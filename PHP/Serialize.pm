#!/usr/bin/perl -w

package PHP::Serialize;
use Exporter;
@ISA = qw/serialize unserialize/;

sub serialize
{
	my $str = shift;
	my $ref = ref($str);
	my $serialized;
	my $temp = "";

	if ($ref =~ /^SCALAR/)
	{
		$temp = $$str;
		$temp =~ s/"/\\"/g;
		$serialized = "s:" . length($temp) . qq<:"$temp">;

	} elsif ($ref =~ /^ARRAY/) {

		my ($count) = 0;

		$serialized = "a:" . scalar(@$str) . ":{";

		foreach (@$str)
		{
			$serialized .= "i:$count;" . serialize(\$_) . ";";
			$count++;
		}

		$serialized .= "}";

	} elsif ($ref =~ /^HASH/) {
	
		my ($count) = 0;

		$serialized = "a:" . scalar(keys(%$str)) . ":{";

		foreach (keys %$str)
		{
			$serialized .= serialize(\$_) . ";" . serialize(\$str->{$_}) . ";";
		}

		$serialized .= "}"
	}

	return $serialized;
}

sub unserialize
{
	my $serialized		= shift;
	my $length		= 0;
	my $unserialized	= "";
	my @parts		= ();
	my $i			= 0;

	if ($serialized =~ /^i:(\d+)$/)
	{
		$unserialized 		= $1;
		return \$unserialized;
		
	} elsif ($serialized =~ /^s:\d+:"(.*[^\\]|)"$/) {

		$unserialized 		= $1;
		$unserialized 		=~ s/\\"/"/;
		return \$unserialized;
		
	} elsif ($serialized =~ /^a:(\d+):{(.*)}$/s) {

		$serialized		= $2;
		$length 		= $1;
		@$unserialized		= ();
		@parts			= split ";",$serialized;
		$i			= -1;

		foreach (@parts)
		{
			$i++;

			if (/^i:\d+$/ || /^s:\d+:"(.*[^\\]|)"$/) next;
			if (//)
		}

		$i			= 0;

		foreach (@parts)
		{
			$unserialized->[$i++] = unserialize($_);
		}

		return $unserialized;
	}
}

1;
