package OF::HTML;

$VERSION = 0.1;

use strict;

sub new
{
	my $class = shift;

	return	bless
		{
		},
		$class || ref($class);

}

sub table
{
	my ($obj,$r_prefs,@data) = @_;
	
	# We're just an alternative wrapper for the verbose table methods
	return $obj->table_start($r_prefs) . join('',@data) . $obj->table_end($r_prefs);
}

sub table_start
{
	# Allow table_start(foo=>bar) or hash ref
	my %prefs = ref $_[0] eq "HASH" ? @_ : %{$_[0]};
	my @cols = ();

	if ($prefs{cols})
	{
		@cols = @{$prefs{cols}};
		delete $prefs{cols};
	}

	# Start output
	my $out = "<table";

	# Default values
	$prefs{border}		= 0 unless exists $prefs{border};
	$prefs{cellpadding}	= 0 unless exists $prefs{cellpadding};
	$prefs{cellspacing}	= 0 unless exists $prefs{cellspacing};

	# Add attributes
	my ($key,$val);
	$out .= qq{ $key="$val"} while ($key,$val) = each(%prefs);

	$out .= ">";

	if (@cols)
	{
		$out .= "<colgroup>";
		
		foreach my $r_col (@cols)
		{
			$out .= "<col";

			$out .= qq{ $key="$val"} while ($key,$val) = each(%{$r_col});

			$out .= " />";
		}

		$out .= "</colgroup>";
	}

	return $out;
}

sub table_end
{
	return "</table>";
}

sub table_row
{
	my ($obj,@cols)	= @_;
	my $out		= "<tr>";
	my $value	= "";
	my ($key,$val);

	foreach my $r_col (@cols)
	{
		$out .= "<td";

		if (exists $r_col->{value})
		{
			$value = $r_col->{value};
			delete $r_col->{value};
		} else {
			$value = "";
		}

		$out .= qq{ $key="$val"} while ($key,$val) = each(%{$r_col});

		$out .= ">$value</td>";
	}

	$out .= "</tr>";

	return $out;
}

sub table_head
{
}

sub form
sub form_start
sub form_end
sub 
sub
sub
sub
sub
sub
sub
sub
sub
sub
sub
sub

return 1;
