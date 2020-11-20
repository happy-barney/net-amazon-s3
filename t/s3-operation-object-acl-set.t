#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_acl_set (
	'API / legacy'                      => \& api_object_acl_set,
	'API / legacy with key'             => \& api_object_acl_set_key,
	'API / named arguments'             => \& api_object_acl_set_named,
	'API / named arguments with key'    => \& api_object_acl_set_named_key,
	'Client'                            => \& client_object_acl_set,
);

had_no_warnings;

done_testing;

sub api_object_acl_set {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (\ %args)
		;
}

sub api_object_acl_set_key {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (delete $args{key}, \ %args)
		;
}

sub api_object_acl_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (%args)
		;
}

sub api_object_acl_set_named_key {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->set_acl (delete $args{key}, %args)
		;
}

sub client_object_acl_set {
	my (%args) = @_;

	build_default_client_object (%args)
		->set_acl (%args)
		;
}

sub should_set_object_acl_using_canned_acl {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			key         => default_object_name,
			acl         => Net::Amazon::S3::ACL::Canned->PRIVATE,
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			key         => default_object_name,
			acl         => expectation_canned_acl ('private'),
			acl_xml     => undef,
		),
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'private',
		},
	}
}

sub should_set_object_acl_using_canned_acl_coercion {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			key         => default_object_name,
			acl         => 'private',
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			key         => default_object_name,
			acl         => expectation_canned_acl ('private'),
			acl_xml     => undef,
		),
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'private',
		},
	}
}

sub should_set_object_acl_using_deprecated_acl_short {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			key         => default_object_name,
			acl_short   => 'public-read',
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			key         => default_object_name,
			acl         => expectation_canned_acl ('public-read'),
			acl_xml     => undef,
		),
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'public-read',
		},
	}
}

sub should_set_object_acl_using_explicit_xml {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			key         => default_object_name,
			acl_xml     => '<?xml version="1.0"?><some-xml-placeholder/>',
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
			key         => default_object_name,
			acl         => undef,
			acl_xml     => '<?xml version="1.0"?><some-xml-placeholder/>',
		),
		expect_request_headers => {
			content_length => 44,
			content_type   => 'application/xml',
		},
		expect_request_content_xml => '<?xml version="1.0"?><some-xml-placeholder/>',
	}
}

sub expect_operation_object_acl_set {
	expect_operation_plan
		implementations         => +{ @_ },
		expect_operation        => 'Net::Amazon::S3::Operation::Object::Acl::Set',
		expect_request_method   => 'PUT',
		expect_request_uri      => default_object_uri . "?acl",
		plan                    => [
			\& should_set_object_acl_using_canned_acl,
			\& should_set_object_acl_using_canned_acl_coercion,
			\& should_set_object_acl_using_deprecated_acl_short,
			\& should_set_object_acl_using_explicit_xml,
		]
}
