#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_create (
	'API / legacy'                      => \& api_add_bucket_legacy,
	'API / named arguments'             => \& api_add_bucket_named,
	'API / trailing named arguments'    => \& api_add_bucket_trailing_named,
	'API / trailing configuration hash' => \& api_add_bucket_trailing_conf,
	'API / create_bucket'               => \& api_create_bucket_named,
	'Client' => \& client_bucket_create,
);

had_no_warnings;

done_testing;

sub api_add_bucket_legacy {
	my (%args) = @_;

	build_default_api->add_bucket (\ %args);
}

sub api_add_bucket_named {
	my (%args) = @_;

	build_default_api->add_bucket (%args);
}

sub api_add_bucket_trailing_named {
	my (%args) = @_;

	build_default_api->add_bucket (delete $args{bucket}, %args);
}

sub api_add_bucket_trailing_conf {
	my (%args) = @_;

	build_default_api->add_bucket (delete $args{bucket}, \%args);
}

sub api_create_bucket_named {
	my (%args) = @_;

	build_default_api->create_bucket (%args);
}

sub client_bucket_create {
	my (%args) = @_;

	build_default_client->create_bucket (name => delete $args{bucket}, %args);
}

sub should_create_bucket {
	+{
		act_arguments => [
			bucket => default_bucket_name,
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
		),
		expect_request_headers => {
			content_length => 0,
		},
	}
}

sub should_create_bucket_with_default_location_constraint {
	+{
		act_arguments => [
			bucket => default_bucket_name,
			location_constraint => 'us-east-1',
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			location_constraint => 'us-east-1',
		),
		expect_request_headers => {
			content_length => 0,
		},
	}
}

sub should_create_bucket_with_nondefault_location_constraint {
	+{
		act_arguments => [
			bucket => default_bucket_name,
			location_constraint => 'ca-central-1',
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			location_constraint => 'ca-central-1',
		),
		expect_request_headers => {
			content_length => 196,
			content_type => 'application/xml',
		},
		expect_request_content_xml  => Shared::Examples::Net::Amazon::S3::fixture ('request::bucket_create_ca_central_1')->{content},
	}
}

sub should_create_bucket_with_acl {
	+{
		act_arguments => [
			bucket    => default_bucket_name,
			acl       => 'public-read',
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			acl         => expectation_canned_acl ('public-read'),
		),
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'public-read',
		},
	}
}

sub expect_operation_bucket_create {
	expect_operation_plan
		implementations         => +{ @_ },
		expect_operation        => 'Net::Amazon::S3::Operation::Bucket::Create',
		expect_request_method   => 'PUT',
		expect_request_uri      => default_bucket_uri,
		plan                    => [
			\& should_create_bucket,
			\& should_create_bucket_with_default_location_constraint,
			\& should_create_bucket_with_nondefault_location_constraint,
			\& should_create_bucket_with_acl,
		]
}
