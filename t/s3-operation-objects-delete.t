#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

# plan tests => 4;

expect_operation_objects_delete (
	'API'     => \& api_objects_delete,
	'Client'  => \& client_objects_delete,
);

had_no_warnings;

done_testing;

sub api_objects_delete {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_multi_object (@{ $args{keys} })
		;
}

sub client_objects_delete {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->delete_multi_object (@{ $args{keys} })
		;
}

sub expect_operation_objects_delete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Objects::Delete',
		expect_request_method => 'POST',
		expect_request_uri    => default_bucket_uri . "?delete",
		plan => {
			"delete multiple objects" => {
				act_arguments => [
					bucket => default_bucket_name,
					keys   => [ 'key-1', 'key-2', 'key-3' ],
				],
				expect_request_headers => {
					content_length => 223,
					content_type   => 'application/xml',
				},
				expect_request_content_xml => <<'EOXML',
<Delete xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<Quiet>true</Quiet>
	<Object><Key>key-1</Key></Object>
	<Object><Key>key-2</Key></Object>
	<Object><Key>key-3</Key></Object>
</Delete>
EOXML
			},
		}
}
