#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-common.pl" }

use Sub::Override;

use Shared::Examples::Net::Amazon::S3 ();
use Shared::Examples::Net::Amazon::S3::API ();
use Shared::Examples::Net::Amazon::S3::Client ();

sub default_hostname {
	's3.amazonaws.com';
}

sub expectation_bucket {
	my ($bucket_name) = @_;
	any (
		obj_isa ('Net::Amazon::S3::Bucket') & methods (bucket => $bucket_name),
		$bucket_name,
	);
}

sub expectation_canned_acl {
	my ($content) = @_;

	$content = $content->canned_acl
		if $content->$Safe::Isa::_isa ('Net::Amazon::S3::ACL::Canned');

	return all (
		obj_isa ('Net::Amazon::S3::ACL::Canned'),
		methods (canned_acl => $content),
	) unless ref $content;

	return $content;
}

sub build_default_api {
	Shared::Examples::Net::Amazon::S3::API->_default_with_api({});
}

sub build_default_api_bucket (\%) {
	my ($args) = @_;

	build_default_api->bucket (delete $args->{bucket});
}

sub build_default_client  {
	Shared::Examples::Net::Amazon::S3::Client->_default_with_api({});
}

sub build_default_client_bucket (\%) {
	my ($args) = @_;

	build_default_client->bucket (name => delete $args->{bucket});
}

sub build_default_client_object (\%) {
	my ($args) = @_;

	build_default_client_bucket (%$args)->object (key => delete $args->{key});
}

sub expect_operation {
	my ($title, %plan) = @_;

	my $guard = Sub::Override->new (
		'Net::Amazon::S3::_perform_operation',
		sub {
			my ($self, $operation, %args) = @_;

			delete $args{error_handler};

			my %construct = %args;
			delete $construct{filename};

			my ($ok, $stack);
			($ok, $stack) = Test::Deep::cmp_details ($operation, $plan{expect_operation});
			diag ("operation expectation failed") unless $ok;

			my $request_class = "$plan{expect_operation}::Request";
			my $request = $request_class->new (s3 => build_default_api, %construct);
			# HTTP::Request but unsigned
			my $guard = Sub::Override->new (
				'Net::Amazon::S3::Request::_build_http_request' => sub {
					my ($self, %params) = @_;

					return $self->_build_signed_request( %params )->_build_request;
				},
			);
			my $raw_request = $request->http_request;

			if ($ok) {
				($ok, $stack) = Test::Deep::cmp_details ($raw_request->method, $plan{expect_request_method});
				diag ("request method expectation failed") unless $ok;
			}

			if ($ok) {
				($ok, $stack) = Test::Deep::cmp_details ($raw_request->uri->as_string, $plan{expect_request_uri});
				diag ("request uri expectation failed") unless $ok;
			}

			if ($ok && $plan{expect_request_headers}) {
				my %headers = $raw_request->headers->flatten;
				for my $key (keys %headers) {
					my $new_key = lc $key;
					$new_key =~ tr/-/_/;
					$headers{$new_key} = delete $headers{$key};
				}

				($ok, $stack) = Test::Deep::cmp_details (\%headers, $plan{expect_request_headers});
				diag ("request headers expectation failed") unless $ok;
			}

			if ($ok && $plan{expect_request}) {
				($ok, $stack) = Test::Deep::cmp_details ($request, $plan{expect_request});
				diag ("request instance expectation failed") unless $ok;
			}

			diag Test::Deep::deep_diag ($stack)
				unless ok $title, got => $ok;

			die bless {}, 'expect_operation';
		}
	);

	my $lives = eval { $plan{act}->(); 1 };
	my $error = $@;
	$error = undef if Scalar::Util::blessed ($error) && ref ($error) eq 'expect_operation';

	if ($lives) {
		fail $title;
		diag "_perform_operation() not called";
		return;
	}

	if ($error) {
		fail $title;
		diag "unexpected_error: $@";
		return;
	}

	return 1;
}

sub expect_operation_plan {
	my (%args) = @_;

	my %expectations = map +($_ => $args{$_}), grep m/^expect_/, keys %args;

	for my $implementation (sort keys %{ $args{implementations} }) {
		my $act = $args{implementations}{$implementation};

		for my $title (sort keys %{ $args{plan} }) {
			my $plan = $args{plan}{$title};

			my %plan_expectations = map +($_ => $plan->{$_}), grep m/^expect_/, keys %{ $plan };

			my @act_arguments = @{ $plan->{act_arguments} || [] };

			expect_operation "$implementation / $title" =>
				act => sub { $act->(@act_arguments) },
				expect_operation => $args{expect_operation},,
				%expectations,
				%plan_expectations,
				;
		}
	}
}

sub _api_expand_headers {
	my (%args) = @_;

	%args = (%args, %{ $args{headers} });
	delete $args{headers};

	%args;
}

sub _api_expand_metadata {
	my (%args) = @_;

	%args = (
		%args,
		map +( "x_amz_meta_$_" => $args{metadata}{$_} ), keys %{ $args{metadata} }
	);

	delete $args{metadata};

	%args;
}

sub _api_expand_header_arguments {
	_api_expand_headers _api_expand_metadata @_;
}

1;
