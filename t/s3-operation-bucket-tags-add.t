#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }
BEGIN { require "$FindBin::Bin/test-helper-tags.pl" }

expect_operation_bucket_tags_set (
	'API / legacy'  => \& api_bucket_tags_set_legacy,
	'API / named'   => \& api_bucket_tags_set_named,
	'Client'  => \& client_bucket_tags_set,
);

had_no_warnings;

done_testing;

sub api_bucket_tags_set_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->add_tags (\ %args)
		;
}

sub api_bucket_tags_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->add_tags (%args)
		;
}

sub client_bucket_tags_set {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->add_tags (%args)
		;
}

sub expect_operation_bucket_tags_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Bucket::Tags::Add',
		expect_request_method => 'PUT',
		expect_request_uri    => default_bucket_uri . "?tagging",
		plan => {
			"set tags on bucket" => {
				act_arguments => [
					bucket      => default_bucket_name,
					tags        => fixture_tags_foo_bar_hashref,
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					tags        => fixture_tags_foo_bar_hashref,
				),
				expect_request_headers => {
					content_length => 210,
					content_type   => 'application/xml',
				},
				expect_request_content_xml => fixture_tags_foo_bar_xml,
			},
		}
}
