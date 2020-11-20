#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_acl_set (
	'API / legacy'          => \& api_bucket_acl_set_legacy,
	'API / named arguments' => \& api_bucket_acl_set_named,
	'Client'                => \& client_bucket_acl_set,
);

had_no_warnings;

done_testing;

sub api_bucket_acl_set_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (\ %args)
		;
}

sub api_bucket_acl_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (%args)
		;
}

sub client_bucket_acl_set {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->set_acl (%args)
		;
}

sub expect_operation_bucket_acl_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Acl::Set',
		expect_request_method => 'PUT',
		expect_request_uri    => default_bucket_uri . "?acl",
		plan => {
			"set bucket acl using acl (canned)" => {
				act_arguments => [
					bucket      => default_bucket_name,
					acl         => 'private',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					acl         => expectation_canned_acl ('private'),
				),
				expect_request_headers => {
					content_length => 0,
					x_amz_acl      => 'private',
				},
			},
			"set bucket acl using acl_short" => {
				act_arguments => [
					bucket      => default_bucket_name,
					acl_short   => 'public-read',
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
			"set bucket acl using acl_xml" => {
				act_arguments => [
					bucket      => default_bucket_name,
					acl_xml     => 'some xml placeholder',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					acl_xml     => 'some xml placeholder',
				),
				expect_request_headers => {
					content_length => 20,
					content_type   => 'application/xml',
				},
			},
		}
}
