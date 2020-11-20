#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

plan tests => 7;

expect_operation_object_tags_set (
	'API / legacy'  => \& api_object_tags_set_legacy,
	'API / named'   => \& api_object_tags_set_named,
	'Client'  => \& client_object_tags_set,
);

had_no_warnings;

done_testing;

sub api_object_tags_set_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->add_tags (\ %args)
		;
}

sub api_object_tags_set_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->add_tags (%args)
		;
}

sub client_object_tags_set {
	my (%args) = @_;

	build_default_client_object (%args)
		->add_tags (%args)
		;
}

sub expect_operation_object_tags_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Tags::Add',
		expect_request_method => 'PUT',
		expect_request_headers => {
			content_length => 167,
			content_type   => 'application/xml',
		},
		plan => {
			"set tags on object" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					tags        => { foo => 'bar' },
				],
				expect_request_uri  => default_object_uri . "?tagging",
				expect_request      => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => default_object_name,
					tags        => { foo => 'bar' },
				),
			},
			"set tags on object version" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					version_id  => 'foo',
					tags        => { foo => 'bar' },
				],
				expect_request_uri  => default_object_uri . "?tagging&versionId=foo",
				expect_request      => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => default_object_name,
					version_id  => 'foo',
					tags        => { foo => 'bar' },
				),
			},
		}
}
