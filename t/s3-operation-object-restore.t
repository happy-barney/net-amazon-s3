#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_restore (
	'Client'    => \& client_object_restore,
);

had_no_warnings;

done_testing;

sub client_object_restore {
	my (%args) = @_;

	build_default_client_object (%args)
		->restore (%args)
		;
}

sub expect_operation_object_restore {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Restore',
		expect_request_method => 'POST',
		expect_request_uri    => default_object_uri . "?restore",
		plan => {
			"abort restore" => {
				act_arguments => [
					bucket      => default_bucket_name,
					key         => default_object_name,
					days        => 42,
					tier        => 'Standard',
				],
				expect_request => methods (
					bucket      => expectation_bucket ('bucket-name'),
					key         => default_object_name,
					days        => 42,
					tier        => 'Standard',
				),
				expect_request_headers => {
					content_length => 202,
					content_type   => 'application/xml',
				},
				expect_request_content_xml => <<'EOXML',
<?xml version="1.0" encoding="utf-8"?>
<RestoreRequest xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<Days>42</Days>
	<GlacierJobParameters>
		<Tier>Standard</Tier>
	</GlacierJobParameters>
</RestoreRequest>
EOXML
			},
		}
}

