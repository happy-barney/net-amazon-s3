#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_upload_part (
	'Client / named arguments'    => \& client_object_upload_part_named_arguments,
	'Client / configuration hash' => \& client_object_upload_part_configuration_hash,
);

had_no_warnings;

done_testing;

sub client_object_upload_part_named_arguments {
	my (%args) = @_;

	build_default_client_object (%args)
		->put_part (%args);
}

sub client_object_upload_part_configuration_hash {
	my (%args) = @_;

	build_default_client_object (%args)
		->put_part (\ %args);
}

sub expect_operation_object_upload_part {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Upload::Part',
		expect_request_method => 'PUT',
		expect_request_uri    => default_object_uri . "?partNumber=1&uploadId=42",
		plan => {
			"upload object part" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					value       => 'foo-bar-baz',
					upload_id   => 42,
					part_number => 1,
					copy_source => 'source-key',
					headers     => {
						x_amz_meta_additional => 'additional-header',
					},
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => default_object_name,
					value       => 'foo-bar-baz',
					upload_id   => 42,
					part_number => 1,
					copy_source => 'source-key',
				),
				expect_request_headers => {
					content_length      => 11,
					x_amz_copy_source   => 'source-key',
					x_amz_meta_additional => 'additional-header',
				},
			},
		}
}

