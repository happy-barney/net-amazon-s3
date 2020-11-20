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

sub expect_operation_object_acl_set {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Acl::Set',
		expect_request_method => 'PUT',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/some-key?acl",
		plan => {
			"set object acl using acl (canned)" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl         => 'private',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					acl         => expectation_canned_acl ('private'),
					acl_xml     => undef,
				),
			},
			"set object acl using acl_short (deprecated)" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl_short   => 'public-read',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					acl         => expectation_canned_acl ('public-read'),
					acl_xml     => undef,
				),
			},
			"set object acl using acl_xml" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					acl_xml     => 'some xml placeholder',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'some-key',
					acl         => undef,
					acl_xml     => 'some xml placeholder',
				),
			},
		}
}
