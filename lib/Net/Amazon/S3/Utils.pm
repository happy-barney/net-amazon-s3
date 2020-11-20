package Net::Amazon::S3::Utils;
# ABSTRACT: misc utils

sub parse_arguments {
	my ($self, $arguments, @spec) = @_;
	my (%aliases, %positional, %optional, %default, @positional);

	my $index = 0;
	while ($index < @spec) {
		my ($name, $spec) = @spec[$index++, $index++];

		$aliases{$name} = $spec->{alias_for} if $spec->{alias_for};
		push @positional, $name if $spec->{positional};
		$positional{$name} = 1 if $spec->{positional};
		$optional{$name} = 1 if $spec->{optional};
		$default{$name} = $spec->{default} if $spec->{default};
	}

	return unless @$arguments;

	my %args;
	%args = %{ pop @$arguments }
		if Ref::Util::is_plain_hashref ($arguments->[-1])
		&& (@$arguments <= 1 + keys %positional)
		;

	$args{$aliases{$_}} = delete $args{$_}
		for grep exists $aliases{$_}, keys %args;

	my $positional_count = scalar grep ! exists $args{$_}, keys %positional;
	while (@$arguments > 1 && @$arguments > $positional_count) {
		my ($name, $value) = splice @$arguments, -2, 2;

		next if exists $args{$name};

		$args{$name} = $value;

		$name = $aliases->{$name} if exists $aliases->{$name};

		if (exists $positional{$name}) {
			$positional_count--;
			delete $positional{$name};
		}
	}

	$args{$aliases{$_}} = delete $args{$_}
		for grep exists $aliases{$_}, keys %args;

	for my $name (@positional) {
		next if exists $args{$name};
		$args{$name} = shift @$arguments;
	}

	$args{$_} = $default{$_}
		for grep ! exists $args{$_}, keys %default;

	return %args;
}


sub parse_arguments_with_bucket {
	return shift->parse_arguments (
		shift,
		bucket => { positional => 1 },
		name => { alias_for => 'bucket' },
		@_,
	);
}

sub parse_arguments_with_bucket_and_object {

	return shift->parse_arguments_with_bucket (
		shift,
		key => { positional => 1 },
		@_,
	);
}

sub parse_arguments_with_object {
	return shift->parse_arguments (
		shift,
		key => { positional => 1 },
		@_,
	);
}

1;

