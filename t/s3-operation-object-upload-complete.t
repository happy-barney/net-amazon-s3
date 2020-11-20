#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_upload_complete (
	'Client / named arguments'    => \& client_object_upload_complete_named_arguments,
	'Client / configuration hash' => \& client_object_upload_complete_configuration_hash,
);

had_no_warnings;

done_testing;

sub client_object_upload_complete_named_arguments {
	my (%args) = @_;

	build_default_client_object (%args)
		->complete_multipart_upload (%args)
		;
}

sub client_object_upload_complete_configuration_hash {
	my (%args) = @_;

	build_default_client_object (%args)
		->complete_multipart_upload (\ %args)
		;
}

sub expect_operation_object_upload_complete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Upload::Complete',
		expect_request_method => 'POST',
		expect_request_uri    => default_object_uri . "?uploadId=42",
		plan => {
			"complete upload" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					upload_id   => 42,
					etags       => [ 'etag-1', 'etag-2' ],
					part_numbers => [ 1, 2 ],
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => default_object_name,
					upload_id   => 42,
					etags       => [ 'etag-1', 'etag-2' ],
					part_numbers => [ 1, 2 ],
				),
				expect_request_headers => {
					content_length => 255,
					content_type   => 'application/xml',
				},
				expect_request_content_xml => <<'EOXML',
<?xml version="1.0" encoding="utf-8"?>
<CompleteMultipartUpload xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<Part>
		<PartNumber>1</PartNumber>
		<ETag>etag-1</ETag>
	</Part>
	<Part>
		<PartNumber>2</PartNumber>
		<ETag>etag-2</ETag>
	</Part>
</CompleteMultipartUpload>
EOXML
			},
		}
}

