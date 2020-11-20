#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-common.pl" }

use Scalar::Util;
use Net::Amazon::S3;

plan tests => 5;

sub act;

subtest "parse_arguments() " => sub {
	local *act = sub { Net::Amazon::S3::Utils->parse_arguments (@_) };

	cmp_deeply "parse_arguments() should recognize named arguments" => (
		got    => { act ([bucket => 'bucket-arg', key => 'key-arg']) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize configuration hash" => (
		got    => { act ([{bucket => 'bucket-arg', key => 'key-arg'}]) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize required positional arguments" => (
		got    => { act (['bucket-arg', 'key-arg'], bucket => { positional => 1 }, key => { positional => 1 }) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize positional argument specified as named" => (
		got    => { act (['bucket-arg', key => 'key-arg'], bucket => { positional => 1 }, key => { positional => 1 }) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize positional argument specified via configuration hash" => (
		got    => { act (['bucket-arg', { key => 'key-arg' }], bucket => { positional => 1 }, key => { positional => 1 }) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should ignore hashref argument passed as named" => (
		got    => { act (['bucket-arg', tags => { tag => 1 }], bucket => { positional => 1 }) },
		expect => { bucket => 'bucket-arg', tags => { tag => 1 } },
	);

	cmp_deeply "parse_arguments() should recognize required positional arguments" => (
		got    => { act (['bucket-arg', 'key-arg'], bucket => {positional => 1}, key => {positional => 1}) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize required positional argument specified as named argument" => (
		got    => { act (['key-arg', bucket => 'bucket-arg'], bucket => {positional => 1}, key => {positional => 1}) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize required positional argument specified as named arguments" => (
		got    => { act ([key => 'key-arg', bucket => 'bucket-arg'], bucket => {positional => 1}, key => {positional => 1}) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize required positional argument specified via configuration hash" => (
		got    => { act (['key-arg', { bucket => 'bucket-arg' }], bucket => {positional => 1}, key => {positional => 1}) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize required positional arguments specified via configuration hash" => (
		got    => { act ([{ key => 'key-arg', bucket => 'bucket-arg' }], bucket => {positional => 1}, key => {positional => 1}) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize combination of named arguments and configuration hash" => (
		got    => { act ([ key => 'key-arg', { bucket => 'bucket-arg' }], bucket => {positional => 1}, key => {positional => 1}) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);

	cmp_deeply "parse_arguments() should recognize alias of required positional argument" => (
		got    => { act (['key-arg', { name => 'bucket-arg' }], bucket => {positional => 1}, key => {positional => 1}, name => { alias_for => 'bucket' }) },
		expect => { bucket => 'bucket-arg', key => 'key-arg' },
	);
};

subtest "parse_arguments_with_bucket()" => sub {
	local *act = sub { Net::Amazon::S3::Utils->parse_arguments_with_bucket (@_) };

	cmp_deeply "should accept bucket as positional argument" => (
		got    => { act (['bucket-arg', optional => 'optional-arg']) },
		expect => { bucket => 'bucket-arg', optional => 'optional-arg' },
	);

	cmp_deeply "should accept bucket as named argument" => (
		got    => { act ([bucket => 'bucket-arg', optional => 'optional-arg']) },
		expect => { bucket => 'bucket-arg', optional => 'optional-arg' },
	);

	cmp_deeply "should accept bucket's alias" => (
		got    => { act ([name => 'bucket-arg', optional => 'optional-arg']) },
		expect => { bucket => 'bucket-arg', optional => 'optional-arg' },
	);
};

subtest "parse_arguments_with_bucket_and_object()" => sub {
	local *act = sub { Net::Amazon::S3::Utils->parse_arguments_with_bucket_and_object (@_) };

	cmp_deeply "should accept bucket and key as positional arguments" => (
		got    => { act (['bucket-arg', 'key-arg', optional => 'optional-arg']) },
		expect => { bucket => 'bucket-arg', key => 'key-arg', optional => 'optional-arg' },
	);
};

subtest "parse_arguments_with_object()" => sub {
	local *act = sub { Net::Amazon::S3::Utils->parse_arguments_with_object (@_) };

	cmp_deeply "should accept key as positional arguments" => (
		got    => { act (['key-arg', optional => 'optional-arg']) },
		expect => { key => 'key-arg', optional => 'optional-arg' },
	);
};

had_no_warnings;

done_testing;

