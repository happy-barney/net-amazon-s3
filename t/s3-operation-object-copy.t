#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_copy (
	'API / legacy'                      => \& api_object_copy_legacy,
	'API / legacy configuration hash'   => \& api_object_copy_legacy_config,
	'API / named arguments'             => \& api_object_copy_named,
	'API / named arguments with keys'   => \& api_object_copy_named_keys,
);

expect_operation_object_edit_metadata (
	'API / edit metadata legacy'        => \& api_object_edit_metadata_legacy,
	'API / edit metadata named'         => \& api_object_edit_metadata_named,
);

had_no_warnings;

done_testing;

sub api_object_copy_legacy {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			delete $args{key},
			delete $args{source},
			\ %args
		);
}

sub api_object_copy_legacy_config {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			\ %args
		);
}

sub api_object_copy_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			%args
		);
}

sub api_object_copy_named_keys {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->copy_key (
			delete $args{key},
			delete $args{source},
			%args
		);
}

sub api_object_edit_metadata_legacy {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->edit_metadata (
			delete $args{key},
			\ %args
		);
}

sub api_object_edit_metadata_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->edit_metadata (
			%args
		);
}

sub expect_operation_object_copy {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/some-key",
		plan => {
			"copy key" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					source      => 'source-key',
					acl_short   => 'public-read',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					value       => '',
					acl         => expectation_canned_acl ('public-read'),
					encryption  => 'object-encryption',
				),
				expect_request_headers => {
					content_encoding    => 'content-encoding',
					content_length      => 0,
					expires             => 2_345_567_890,
					x_amz_acl           => 'public-read',
					x_amz_copy_source   => 'source-key',
					x_amz_meta_foo      => 'foo-value',
					x_amz_metadata_directive => 'REPLACE',
					x_amz_server_side_encryption => 'object-encryption',
					x_amz_storage_class => 'storage-class',
					x_amz_website_redirect_location => 'location-value',
				},
			},
		}
}

sub expect_operation_object_edit_metadata {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/some-key",
		plan => {
			"copy key" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl_short   => 'public-read',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'storage-class',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					value       => '',
					acl         => expectation_canned_acl ('public-read'),
					encryption  => 'object-encryption',
				),
				expect_request_headers => {
					content_encoding    => 'content-encoding',
					content_length      => 0,
					expires             => 2_345_567_890,
					x_amz_acl           => 'public-read',
					x_amz_copy_source   => '/bucket-name/some-key',
					x_amz_meta_foo      => 'foo-value',
					x_amz_metadata_directive => 'REPLACE',
					x_amz_server_side_encryption => 'object-encryption',
					x_amz_storage_class => 'storage-class',
					x_amz_website_redirect_location => 'location-value',
				},
			},
		}
}

