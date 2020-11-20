#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_buckets_list (
	"API / buckets"      => \& api_buckets,
	"API / list_buckets" => \& api_list_buckets,
	"Client / buckets"   => \& client_buckets,
);

had_no_warnings;

done_testing;

sub api_buckets {
	my (%args) = @_;

	build_default_api->buckets (%args);
}

sub api_list_buckets {
	my (%args) = @_;

	build_default_api->list_buckets (%args);
}

sub client_buckets {
	my (%args) = @_;

	build_default_client->buckets (%args);
}

sub should_list_buckets {
	+{
		act_arguments => [
		],
		expect_request_headers => {
			content_length => 0,
		},
	}
}

sub expect_operation_buckets_list {
	expect_operation_plan
		implementations         => +{ @_ },
		expect_operation        => 'Net::Amazon::S3::Operation::Buckets::List',
		expect_request_method   => 'GET',
		expect_request_uri      => default_uri,
		plan                    => [
			\& should_list_buckets,
		]
}
