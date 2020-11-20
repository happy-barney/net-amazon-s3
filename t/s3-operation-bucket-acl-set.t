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

sub should_set_bucket_acl_using_canned_acl {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			acl         => Net::Amazon::S3::ACL::Canned->PRIVATE,
		],
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'private',
		},
	}
}

sub should_set_bucket_acl_using_canned_acl_coercion {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			acl         => 'private',
		],
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'private',
		},
	}
}

sub should_set_bucket_acl_using_deprecated_acl_short {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			acl_short   => 'public-read',
		],
		expect_request_headers => {
			content_length => 0,
			x_amz_acl      => 'public-read',
		},
	}
}

sub should_set_bucket_acl_using_explicit_xml {
	+{
		act_arguments => [
			bucket      => default_bucket_name,
			acl_xml     => '<?xml version="1.0"?><some-xml-placeholder/>',
		],
		expect_request_headers => {
			content_length => 44,
			content_type   => 'application/xml',
		},
		expect_request_content_xml => '<?xml version="1.0"?><some-xml-placeholder/>',
	}
}

sub expect_operation_bucket_acl_set {
	expect_operation_plan
		implementations         => +{ @_ },
		expect_operation        => 'Net::Amazon::S3::Operation::Bucket::Acl::Set',
		expect_request_method   => 'PUT',
		expect_request_uri      => default_bucket_uri . "?acl",
		plan                    => [
			\& should_set_bucket_acl_using_canned_acl,
			\& should_set_bucket_acl_using_canned_acl_coercion,
			\& should_set_bucket_acl_using_deprecated_acl_short,
			\& should_set_bucket_acl_using_explicit_xml,
		]
}
