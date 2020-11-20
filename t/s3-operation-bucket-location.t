#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_bucket_location (
	'API / legacy'  => \& api_bucket_location_legacy,
	'API / named'   => \& api_bucket_location_named,
	'Client' => \& client_bucket_location,
);

had_no_warnings;

done_testing;

sub api_bucket_location_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_location_constraint (\ %args)
		;
}

sub api_bucket_location_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_location_constraint (%args)
		;
}

sub client_bucket_location {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->location_constraint (%args)
		;
}

sub should_fetch_bucket_location {
	+{
		act_arguments => [
			bucket => default_bucket_name,
		],
		expect_request => methods (
			bucket      => expectation_bucket ('bucket-name'),
		),
		expect_request_headers => {
			content_length => 0,
		},
	}
}

sub expect_operation_bucket_location {
	expect_operation_plan
		implementations         => +{ @_ },
		expect_operation        => 'Net::Amazon::S3::Operation::Bucket::Location',
		expect_request_method   => 'GET',
		expect_request_uri      => default_bucket_uri . "?location",
		plan => [
			\& should_fetch_bucket_location,
		]
}
