#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_acl_fetch (
	'API / legacy'      => \& api_object_acl_fetch_legacy,
	'API / config hash' => \& api_object_acl_fetch_config_hash,
	'API / named'       => \& api_object_acl_fetch_named,
);

had_no_warnings;

done_testing;

sub api_object_acl_fetch_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl ($args{key})
		;
}

sub api_object_acl_fetch_config_hash {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl ( \%args)
		;
}

sub api_object_acl_fetch_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_acl (%args)
		;
}

sub should_fetch_object_acl {
	+{
		act_arguments => [
			bucket => default_bucket_name,
			key    => default_object_name,
		],
		expect_request_headers => {
			content_length => 0,
		},
	}
}

sub expect_operation_object_acl_fetch {
	expect_operation_plan
		implementations         => +{ @_ },
		expect_operation        => 'Net::Amazon::S3::Operation::Object::Acl::Fetch',
		expect_request_method   => 'GET',
		expect_request_uri      => default_object_uri . "?acl",
		plan                    => [
			\& should_fetch_object_acl,
		]
}
