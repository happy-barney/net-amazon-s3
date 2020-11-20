#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

note "Client and API capabilities differs a lot";

expect_operation_object_add_scalar (
	'API / via Bucket / legacy'          => \& api_add_object_scalar_bucket_legacy,
	'API / via Bucket / positional'      => \& api_add_object_scalar_bucket_positional,
	'API / via Bucket / named arguments' => \& api_add_object_scalar_bucket_named,
	'API / via S3 / legacy'              => \& api_add_object_scalar_s3_legacy,
	'API / via S3 / positional'          => \& api_add_object_scalar_s3_positional,
	'API / via S3 / named arguments'     => \& api_add_object_scalar_s3_named,
);

expect_operation_object_add_file (
	'API / add key wrapper' => \& api_object_add_filename,
	'API / add key'         => \& api_object_add_file,
	'API / add key wrapper / named arguments' => \& api_object_add_filename_named,
);

expect_operation_object_client_add_scalar (
	'Client'  => \& client_object_add_scalar,
);

expect_operation_object_client_add_file (
	'Client / add key filename'  => \& client_object_add_filename,
);

had_no_warnings;

done_testing;

sub api_add_object_scalar_bucket_legacy {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (
			delete $args{key},
			delete $args{value},
			\ %args
		);
}

sub api_add_object_scalar_bucket_positional {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (
			delete $args{key},
			delete $args{value},
			%args
		);
}

sub api_add_object_scalar_bucket_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (%args)
		;
}

sub api_add_object_scalar_s3_legacy {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api
		->add_key (\ %args)
		;
}

sub api_add_object_scalar_s3_positional {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api
		->add_key (
			delete $args{bucket},
			delete $args{key},
			delete $args{value},
			%args,
		)
		;
}

sub api_add_object_scalar_s3_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api
		->add_key (%args)
		;
}

sub api_object_add_file {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key (
			delete $args{key},
			\ delete $args{value},
			\ %args
		);
}

sub api_object_add_filename {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key_filename (
			delete $args{key},
			delete $args{value},
			\ %args
		);
}

sub api_object_add_filename_named {
	my (%args) = _api_expand_header_arguments @_;

	build_default_api_bucket (%args)
		->add_key_filename (
			delete $args{key},
			delete $args{value},
			\ %args
		);
}

sub client_object_add_scalar {
	my (%args) = @_;
	my $headers = delete $args{headers};
	build_default_client_bucket (%args)
		->object (
			key => $args{key},
			expires => 2_345_567_890,
			storage_class => $headers->{x_amz_storage_class},
			website_redirect_location => $headers->{x_amz_website_redirect_location},
			user_metadata => $args{metadata},
			content_encoding => $headers->{content_encoding},
			acl => $args{acl},
			encryption => $args{encryption},
		)
		->put ($args{value})
		;
}

sub client_object_add_filename {
	my (%args) = @_;
	my $headers = delete $args{headers};
	build_default_client_bucket (%args)
		->object (
			key => $args{key},
			expires => 2_345_567_890,
			storage_class => $headers->{x_amz_storage_class},
			website_redirect_location => $headers->{x_amz_website_redirect_location},
			user_metadata => $args{metadata},
			content_encoding => $headers->{content_encoding},
			acl => $args{acl},
			encryption => $args{encryption},
		)
		->put_filename ($args{value})
		;
}

sub expect_operation_object_add_scalar {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => default_object_uri,
		plan => {
			"add object with value from scalar" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					value       => 'baz-€',
					acl         => 'private',
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
				expect_request_headers => {
					expires             => 2_345_567_890,
					content_encoding    => 'content-encoding',
					content_length      => 7, # € - 1 char but 3 bytes
					x_amz_acl           => 'private',
					x_amz_meta_foo      => 'foo-value',
					x_amz_server_side_encryption => 'object-encryption',
					x_amz_storage_class => 'storage-class',
					x_amz_website_redirect_location => 'location-value',
				},
			},
		}
}

sub expect_operation_object_add_file {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => default_object_uri,
		plan => {
			"add object with value from file" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					value       => "$FindBin::Bin/data/s3-operation-object-add.txt",
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 2_345_567_890,
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_request_headers => {
					expires             => 2_345_567_890,
					content_encoding    => 'content-encoding',
					content_length      => 72,
					expect              => '100-continue',
					x_amz_acl           => 'private',
					x_amz_meta_foo      => 'foo-value',
					x_amz_server_side_encryption => 'object-encryption',
					x_amz_storage_class => 'standard',
					x_amz_website_redirect_location => 'location-value',
				},
			},
		}
}

sub expect_operation_object_client_add_scalar {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => default_object_uri,
		plan => {
			"add object with value from scalar" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					value       => 'foo-bar-baz',
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 'expires-value',
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_request_headers => {
					content_length      => 11,
					content_type        => 'binary/octet-stream',
					content_md5         => ignore,
					content_encoding    => 'content-encoding',
					expires             => 'Fri, 29 Apr 2044 18:38:10 GMT',
					x_amz_acl           => 'private',
					x_amz_meta_foo      => 'foo-value',
					x_amz_server_side_encryption => 'object-encryption',
					x_amz_website_redirect_location => 'location-value',
				},
			},
		}
}

sub expect_operation_object_client_add_file {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => default_object_uri,
		plan => {
			"add object with value from scalar" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					value       => "$FindBin::Bin/data/s3-operation-object-add.txt",
					acl         => 'private',
					encryption  => 'object-encryption',
					headers     => {
						expires     => 'expires-value',
						content_encoding => 'content-encoding',
						x_amz_storage_class => 'standard',
						x_amz_website_redirect_location => 'location-value',
					},
					metadata => {
						foo => 'foo-value',
					},
				],
				expect_request_headers => {
					content_length      => 72,
					content_type        => 'binary/octet-stream',
					content_md5         => ignore,
					content_encoding    => 'content-encoding',
					expires             => 'Fri, 29 Apr 2044 18:38:10 GMT',
					x_amz_acl           => 'private',
					x_amz_meta_foo      => 'foo-value',
					x_amz_server_side_encryption => 'object-encryption',
					x_amz_website_redirect_location => 'location-value',
				},
			},
		}
}

