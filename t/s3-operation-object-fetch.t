#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_fetch (
	'API / S3->get_key / legacy'                        => \& api_get_key_s3_legacy,
	'API / S3->get_key / positional'                    => \& api_get_key_s3_positional,
	'API / S3->get_key / named arguments'               => \& api_get_key_s3_named,
	'API / S3->get_key / into file'                     => \& api_get_key_s3_file,
	'API / Bucket->get_key / legacy'                    => \& api_get_key_legacy,
	'API / Bucket->get_key / named arguments'           => \& api_get_key_named,
	'API / Bucket->get_key into file / legacy'          => \& api_get_key_file_legacy,
	'API / Bucket->get_key into file / named arguments' => \& api_get_key_file_named,
);

expect_operation_object_head (
	'API / head key legacy'                 => \& api_object_head_legacy,
	'API / head key named arguments'        => \& api_object_head_named,
);

expect_operation_object_fetch_content (
	'Client' => \& client_object_fetch_content,
	'Client' => \& client_object_fetch_decoded_content,
);

expect_operation_object_fetch_filename (
	'API' => \& api_object_fetch_filename,
	'Client' => \& client_object_fetch_filename,
);

expect_operation_object_fetch_callback (
	'Client' => \& client_object_fetch_callback,
);

had_no_warnings;

done_testing;

sub api_get_key_s3_legacy {
	my (%args) = @_;

	build_default_api->get_key (\ %args);
}

sub api_get_key_s3_positional {
	my (%args) = @_;

	build_default_api->get_key (
		delete $args{bucket},
		delete $args{key},
		%args
	);
}

sub api_get_key_s3_named {
	my (%args) = @_;

	build_default_api->get_key (%args);
}

sub api_get_key_s3_file {
	my (%args) = @_;

	build_default_api->get_key (
		filename => \ delete $args{filename},
		%args,
	);
}

sub api_get_key_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_key (
			$args{key},
			$args{method},
			$args{filename},
		)
		;
}

sub api_get_key_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_key (%args)
		;
}

sub api_get_key_file_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_key (
			$args{key},
			$args{method},
			\ $args{filename},
		)
		;
}

sub api_get_key_file_named {
	my (%args) = @_;

	$args{filename} = \ delete $args{filename};

	build_default_api_bucket (%args)
		->get_key (%args)
		;
}

sub api_object_fetch_filename {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->get_key_filename (
			$args{key},
			$args{method},
			$args{filename},
		)
		;
}

sub client_object_fetch_content {
	my (%args) = @_;

	build_default_client_object (%args)
		->get
		;
}

sub client_object_fetch_decoded_content {
	my (%args) = @_;

	build_default_client_object (%args)
		->get_decoded
		;
}

sub client_object_fetch_filename {
	my (%args) = @_;

	build_default_client_object (%args)
		->get_filename ($args{filename})
		;
}

sub client_object_fetch_callback {
	my (%args) = @_;

	build_default_client_object (%args)
		->get_callback ($args{filename})
		;
}

sub api_object_head_legacy {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->head_key (
			$args{key},
		)
		;
}

sub api_object_head_named {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->head_key (%args)
		;
}

sub expect_operation_object_fetch {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Fetch',
		expect_request_method => 'GET',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/key-name",
		plan => {
			"fetch object" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
					method => 'GET',
					filename => 'foo',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'key-name',
				),
				expect_request_headers => {
					content_length => 0,
				},
			},
		}
}

sub expect_operation_object_fetch_content {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Fetch',
		expect_request_method => 'GET',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/key-name",
		plan => {
			"fetch object content" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'key-name',
				),
				expect_request_headers => {
					content_length => 0,
				},
			},
		}
}

sub expect_operation_object_fetch_filename {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Fetch',
		expect_request_method => 'GET',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/key-name",
		plan => {
			"fetch object into file" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
					method => 'GET',
					filename => 'foo',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'key-name',
				),
				expect_request_headers => {
					content_length => 0,
				},
			},
		}
}

sub expect_operation_object_fetch_callback {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Fetch',
		expect_request_method => 'GET',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/key-name",
		plan => {
			"fetch object with callback" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
					method => 'GET',
					filename => sub { },
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'key-name',
				),
				expect_request_headers => {
					content_length => 0,
				},
			},
		}
}

sub expect_operation_object_head {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Fetch',
		expect_request_method => 'HEAD',
		expect_request_uri    => "https://bucket-name.${ \ default_hostname }/key-name",
		plan => {
			"head key" => {
				act_arguments => [
					bucket => 'bucket-name',
					key    => 'key-name',
					method => 'HEAD',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => 'key-name',
				),
				expect_request_headers => {
					content_length => 0,
				},
			},
		}
}

