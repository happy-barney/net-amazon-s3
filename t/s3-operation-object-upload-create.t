#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_upload_create (
	'Client / named arguments'    => \& client_object_upload_create_named_arguments,
	'Client / configuration hash' => \& client_object_upload_create_configuration_hash,
);

had_no_warnings;

done_testing;

sub client_object_upload_create_named_arguments {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->object (
			key => delete $args{key},
			(exists $args{encryption} ? (encryption => delete $args{encryption}) : ()),
			(exists $args{object_acl} ? (acl        => delete $args{object_acl}) : ()),
		)
		->initiate_multipart_upload (%args)
		;
}

sub client_object_upload_create_configuration_hash {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->object (
			key => delete $args{key},
			(exists $args{encryption} ? (encryption => delete $args{encryption}) : ()),
			(exists $args{object_acl} ? (acl        => delete $args{object_acl}) : ()),
		)
		->initiate_multipart_upload (\ %args)
		;
}

sub expect_operation_object_upload_create {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Upload::Create',
		expect_request_method => 'POST',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/some-key?uploads",
		plan => {
			"create upload with object acl" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					object_acl  => 'private',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					encryption  => undef,
					acl         => expectation_canned_acl ('private'),
				),
			},
			"create upload with overloaded acl" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl         => 'private',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					encryption  => undef,
					acl         => expectation_canned_acl ('private'),
				),
			},
			"create upload with acl_short" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl_short   => 'private',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					encryption  => undef,
					acl         => expectation_canned_acl ('private'),
				),
			},
			"create upload with additional headers" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					headers     => { x_amz_meta_additional => 'additional-header' },
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					encryption  => undef,
					acl         => undef,
					headers     => { x_amz_meta_additional => 'additional-header' },
				),
			},
			"create upload with server-side encoding" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					encryption  => 'AES256',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					encryption  => 'AES256',
					acl         => undef,
				),
			},
		}
}

