package Timestamp;

$VERSION = 1.2;

use Carp;
use POSIX;
use strict;
use vars qw/$AUTOLOAD/;
use overload
	'+'	=> \&add,
	'-'	=> \&subtract,
	'<'	=> \&less_than,
	'>'	=> \&greater_than,
	'<='	=> \&less_than_eq,
	'>='	=> \&greater_than_eq,
	'=='	=> \&eq;

{
	my @_fields = qw/second minute hour day month year/;

	my @_days_per_mon = qw//;

	my $_fix = sub
	{
		my $obj = shift;
		my $days;

		$obj->min += int($obj->sec / 60);
		$obj->sec %= 60;

		$obj->hr  += int($obj->min / 60);
		$obj->min %= 60;

		$obj->day += int($obj->hr / 24);
		$obj->hr  %= 24;

		do
		{
			$obj->year += int($obj->mon / 12);
			$obj->mon  %= 12;

			$days = $_days_per_mon[$obj->mon];

			$obj->mon += int($obj->day / $days);
			$obj->day %= $days;

		} while ($obj->day > $days);

		return;
	};

	my $_anaylze_args =
	sub
	{
		my ($obj,@args) = @_;

		if (length @args == 1)
		{
			my $arg = $args[0];

			$obj->load_object($arg),	return if ref($arg) eq ref($obj);
			$obj->load_string($arg),	return if $arg =~ /^\d{14}$/;
			$obj->load_unix($arg),		return if $arg =~ /^\d+$/;
			$obj->load_logical($arg);

		} elsif (length @args) {

			# Assume it's a hash
			$obj->load(@args);
		}

		return;
	};

	sub new
	{
		my $pkg = shift;

		my $obj =	bless
				{
					second	=> 0,
					minute	=> 0,
					hour	=> 0,
					month	=> 0,
					day	=> 0,
					year	=> 0,

				},ref($pkg) || $pkg;

		&{$_anaylze_args}($obj,@_);

		# When invoked off of another object, copy its values
		%{$obj} = %{$pkg} if ref($pkg);

		return $obj;
	}

	sub format
	{
		my ($obj,$fmt) = @_;

		return	strftime
			(
				$fmt,
				$obj->sec,$obj->min,$obj->hr,
				$obj->day,$obj->mon,$obj->year
			);
	}

	sub load_now
	{
		my $obj = shift;
		my ($sec,$min,$hour,$day,$mon,$year) = localtime(time());

		$obj->load
		(
			second	=> $sec,
			minute	=> $min,
			hour	=> $hour,
			month	=> $mon + 1,
			day	=> $day,
			year	=> $year + 1900
		);

		return;
	}

	my %_dup_fields =	(
					sec	=> "second",
					min	=> "minute",
					hr	=> "hr",
					mon	=> "month"
				);

	my $_in_array	=
	sub
	{
		my ($r_arr,$str) = @_;
		my $i = 0;

		foreach (@$r_arr)
		{
			return $i if $_ eq $str;
			$i++;
		}

		return undef;
	};

	sub AUTOLOAD
	{
		my $obj = shift;

		# Check if the method name is in our field list
		if (defined(my $index = &{$_in_array}([@_fields,keys %_dup_fields],$AUTOLOAD)))
		{
			$AUTOLOAD = $_dup_fields{$AUTOLOAD} if $index > @_fields;

			# Memoize method
			*$AUTOLOAD = eval '
			sub
			{
				$_[1] ?
				$_[0]->{' . $AUTOLOAD . '} = $_[1] :
				$_[0]->{' . $AUTOLOAD . '}
			}';

			# Call method
			goto &{$AUTOLOAD};
		}

		croak "No such method: $AUTOLOAD";
	}

	sub retrieve_string
	{
		my $obj = shift;

		return	sprintf
			(
				"%04d" . ("%02d" x 5),
				$obj->year,$obj->mon,$obj->day,
				$obj->hour,$obj->min,$obj->sec
			);
	}

	sub retrieve_unix
	{
		my $obj = shift;

		return	mktime
			(
				$obj->sec,$obj->min,$obj->hr,
				$obj->day,$obj->mon,$obj->year
			);
	}

	sub add
	{
		my ($obj,$arg) = @_;

		if (ref($arg) eq ref($obj))
		{
			$obj->{$_} += $arg->{$_} foreach (@_fields);
		} else {
			# Else treat it as seconds
			$obj->{second} += $arg;
		}

		return;
	}

	sub less_than
	{
		my ($obj,$arg)	= @_;
		my $op		= $obj->new($arg);

		foreach (@_fields)
		{
			return $obj->$_ - $op->$_ < 0 ? 1 : 0 if $obj->$_ - $op->$_;
		}

		# Must be equal, so $obj is not less than $op
		return 0;
	}

	sub less_than_eq
	{
		return &less_than or &eq;
	}

	sub eq
	{
		my ($obj,$arg)	= @_;
		my $op		= $obj->new($arg);
		my $ret		= 0;

		# Tally up how many are the same
		foreach (@_fields)
		{
			$ret .= $obj->$_ == $op->$_ ? 1 : 0;
		}

		# They're equal if all are the same
		return $ret == @_fields;
	}

	sub greater_than
	{
		my ($obj,$arg) = @_;

		return $arg->less_than($obj);
	}

	sub greater_than_eq
	{
		return &greater_than or &eq;
	}
}

return 1;
