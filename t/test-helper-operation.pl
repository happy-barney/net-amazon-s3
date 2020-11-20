#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-common.pl" }

use Ref::Util;
use Sub::Override;
use Sub::Util;

use Shared::Examples::Net::Amazon::S3 ();
use Shared::Examples::Net::Amazon::S3::API ();
use Shared::Examples::Net::Amazon::S3::Client ();

sub default_hostname {
	's3.amazonaws.com';
}

sub default_bucket_name {
	'dummy-bucket-name',
}

sub default_object_name {
	'dummy-key-name',
}

sub default_uri {
	"https://${\ default_hostname }/";
}

sub default_bucket_uri {
	"https://${\ default_bucket_name }.${\ default_hostname }/";
}

sub default_object_uri {
	"https://${\ default_bucket_name }.${\ default_hostname }/${\ default_object_name }";
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

sub _expand_operation_plan (\%) {
	my ($args) = @_;

	return unless $args->{plan};
	return unless Ref::Util::is_plain_arrayref ($args->{plan});

	my %plan;
	for my $entry (@{ $args->{plan} }) {
		die "Arrayref plan expects code refs" unless Ref::Util::is_plain_coderef ($entry);
		my $title = Sub::Util::subname ($entry);
		$title =~ s/.*:://;
		$title =~ tr/_/ /;
		$plan{$title} = $entry->();
	}

	$args->{plan} = \%plan;
}

sub _build_operation_request {
	my ($operation, %args) = @_;

	delete $args{error_handler};
	delete $args{filename};

	my $request_class = "${operation}::Request";

	return $request_class->new (s3 => build_default_api, %args);
}

sub _expectation {
	my ($title, $message, $ok, $stack) = @_;

	unless ($ok) {
		fail $title;
		diag $message;
		diag Test::Deep::deep_diag $stack
	}

	return $ok;
}

sub _expectation_operation {
	my ($title, %args) = @_;

	return _expectation
		$title,
		"Operation type expectation",
		Test::Deep::cmp_details ($args{operation}, $args{expect}),
		;
}

sub _expectation_request_method {
	my ($title, %args) = @_;

	return _expectation
		$title,
		"Request method expectation",
		Test::Deep::cmp_details ($args{request}->http_request->method, $args{expect}),
		;
}

sub _expectation_request_uri {
	my ($title, %args) = @_;

	return _expectation
		$title,
		"Request uri expectation",
		Test::Deep::cmp_details ($args{request}->http_request->uri->as_string, $args{expect}),
		;
}

sub _http_headers_for_test {
	my ($http_message) = @_;

	my %headers = $http_message->headers->flatten;
	for my $key (keys %headers) {
		(my $new_key = lc $key) =~ tr/-/_/;
		$headers{$new_key} = delete $headers{$key};
	}

	return %headers;
}

sub _expectation_request_headers {
	my ($title, %args) = @_;

	return 1 unless $args{expect};

	my %headers = _http_headers_for_test ($args{request}->http_request);

	unless ($args{expect}->$Safe::Isa::_isa ('Test::Deep::Cmp')) {
		for my $key (qw[ content_type content_length authorization date ]) {
			delete $headers{$key} unless exists $args{expect}->{$key};
		}
	}

	return _expectation
		$title,
		"Request headers expectation",
		Test::Deep::cmp_details (\%headers, $args{expect}),
		;
}

sub _expectation_request_instance {
	my ($title, %args) = @_;

	return 1 unless $args{expect_request};

	return _expectation
		$title,
		"Request instance expectation",
		Test::Deep::cmp_details ($args{request}, $args{expect_request}),
		;
}

sub _expectation_request_content_xml {
	my ($title, %args) = @_;

	require Shared::Examples::Net::Amazon::S3::Request;

	return 1 unless $args{expect};

	my $got    = Shared::Examples::Net::Amazon::S3::Request::_canonical_xml ($args{request}->http_request->content);
	my $expect = Shared::Examples::Net::Amazon::S3::Request::_canonical_xml ($args{expect});

	return _expectation
		$title,
		"Request content XML expectation",
		Test::Deep::cmp_details ($got, $expect),
		;
}

my %operation_request_tests = (
	expect_request                  => \& _expectation_request_instance,
	expect_request_content_xml      => \& _expectation_request_content_xml,
	expect_request_headers          => \& _expectation_request_headers,
	expect_request_method           => \& _expectation_request_method,
	expect_request_uri              => \& _expectation_request_uri,
);

sub expect_operation {
	my ($title, %plan) = @_;

	my $guard = Sub::Override->new (
		'Net::Amazon::S3::_perform_operation',
		sub {
			my ($self, $operation, %args) = @_;

			my $subtest = sub {
				return unless _expectation_operation $title =>
					operation => $operation,
					expect    => $plan{expect_operation},
					;

				my $request = _build_operation_request ($operation, %args);

				for my $test (sort keys %operation_request_tests) {
					return unless $operation_request_tests{$test}->($title => (
						request => $request,
						expect  => $plan{$test},
					));
				}

				pass $title;
			};

			$subtest->();

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

	_expand_operation_plan %args;

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
