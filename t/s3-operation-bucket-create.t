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

sub expect_operation_bucket_create {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Create',
		expect_request_method => 'PUT',
		expect_request_uri    => default_bucket_uri,
		plan => {
			"create bucket with name" => {
				act_arguments => [
					bucket => default_bucket_name,
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
				),
				expect_request_headers => {
					content_length => 0,
				},
			},
			"create bucket with location constraint" => {
				act_arguments => [
					bucket => default_bucket_name,
					location_constraint => 'eu-west-1',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					location_constraint => 'eu-west-1',
				),
				expect_request_headers => {
					content_length => 193,
					content_type => 'application/xml',
				},
			},
			"create bucket with acl" => {
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
			},
		}
}
