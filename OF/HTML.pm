# By Jared Yanovich <jaredy@closeedge.net>
# Wednesday, March 05, 2003 10:05:29 AM
# OF - output format library
package OF::HTML;

$VERSION = 0.1;

use constant OF_LIST_OD => 1;
use constant OF_LIST_UN => 2;

# mod_perl speed enhancements
BEGIN:
{
	if ($ENV{MOD_PERL})
	{
		require Apache::Request;
	} else {
		require CGI;
	}
}

use strict;

sub new
{
	my $class = shift;

	return	bless
		{
		},
		$class || ref($class);
}

{
	my $cgi;
	
	sub _cgi
	{
		unless ($cgi)
		{
			if ($ENV{MOD_PERL})
			{
				$cgi = new Apache::Request;
			} else {
				$cgi = new CGI;
			}
		}

		return $cgi;
	}
}

sub _loadpref
{
	return;
}

sub table
{
	my ($this,$r_prefs,@data) = @_;
	
	# Not a preference hash reference, must be a piece of @data
	unless (ref($r_prefs) eq "HASH")
	{
		unshift @data,$r_prefs;
		$r_prefs = {};
	}
	
	return $this->table_start($r_prefs) . join('',@data) . $this->table_end($r_prefs);
}

sub table_start
{
	# Allow table_start(foo=>bar) or hash ref
	my $this	= shift;
	my %prefs	= ref $_[0] eq "HASH" ? %{$_[0]} : @_;
	my @cols	= ();

	if ($prefs{cols})
	{
		@cols = @{$prefs{cols}};
		delete $prefs{cols};
	}

	# Start output
	my $out = "<table";

	# Load default preferences
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
	my ($this,@cols)	= @_;
	my $out			= "<tr>";
	my $value		= "";
	my ($key,$val);

	foreach my $r_col (@cols)
	{
		$value = "";
		$out .= "<td";

		if (ref($r_col) eq "HASH")
		{
			if (exists $r_col->{value})
			{
				$value = $r_col->{value};
				delete $r_col->{value};
			}
		} else {
			$value = $r_col;
		}

		# Load default preferences

		$out .= qq{ $key="$val"} while ($key,$val) = each(%{$r_col});

		$out .= ">$value</td>";
	}

	$out .= "</tr>";

	return $out;
}

sub table_head
{
	my ($this,@headers)	= @_;
	my $out			= "<tr>";
	my $value		= "";
	my ($key,$val);

	foreach my $r_header (@headers)
	{
		$value = "";
		$out .= "<th";

		if (ref($r_header) eq "HASH")
		{
			# `r_header' is actually a hash containing
			# header preferences
			if (exists $r_header->{value})
			{
				$value = $r_header->{value};
				delete $r_header->{value};
			}
		} else {
			# `r_header' is just the header value
			$value = $r_header;
		}

		# Load default preferences

		$out .= qq{ $key="$val"} while ($key,$val) = each(%{$r_header});

		$out .= ">$value</th>";
	}

	$out .= "</tr>";

	return $out;
}

sub form
{
	my ($this,$r_prefs,@data) = @_;

	# Not a preference hash reference, must be a piece of @data
	unless (ref($r_prefs) eq "HASH")
	{
		unshift @data,$r_prefs;
		$r_prefs = {};
	}

	return $this->form_start($r_prefs) . join('',@data) . $this->form_end($r_prefs);
}

sub form_start
{
	my $this	= shift;
	my %prefs	= ref $_[0] eq "HASH" ? %{$_[0]} : @_;

	# Load default preferences
	$prefs{action}	= $this->url(-absolute=>1) unless exists $prefs{action};
	$prefs{method}	= "post" unless exists $prefs{method};

# Note we could have OF::HTML::input() set a var when a file input
# is requested to default to multipart/form-data
	$prefs{enctype}	= "application/x-www-form-urlencoded" unless exists $prefs{enctype};

	my $out = "<form";

	my ($key,$val);

	$out .= qq{ $key="$val"} while ($key,$val) = each(%prefs);

	$out .= ">";

	return $out;
}

sub form_end
{
	return "</form>";
}

sub fieldset
{
	return "<fieldset>" . join('',@_[1..$#_]) . "</fieldset>";
}

sub p
{
	my ($this,$r_prefs,@data) = shift;

	unless (ref($r_prefs) eq "HASH")
	{
		unshift @data,$r_prefs;
		$r_prefs = {};
	}

	my $out = "<p";
	
	my ($key,$val);
	$out .= qq{ $key="$val"} while ($key,$val) = each(%$r_prefs);
	
	$out .= ">" . join('',@data) . "</p>";
	
	return $out;
}

sub link
{
	my ($this,%prefs) = @_;

	# link(obj,value,link)
	if (@_ == 3)
	{
		my $valid = 1;

		foreach my $i (keys %prefs)
		{
			# Check for valid key names
			unless ($i =~ /^[^a-z]+$/)
			{
				$valid = 0;
				last;
			}
		}

		%prefs = (href=>${[%prefs]}->[1],value=>${[%prefs]}->[0]) unless $valid;
	}

	my $value;
	
	if (exists $prefs{value})
	{
		$value = $prefs{value};
		delete $prefs{value};
	}

	my $out = "<a";

	my ($key,$val);
	$out .= qq{ $key="$val"} while ($key,$val) = each(%prefs);

	$out .= defined $value ? ">$value</a>" : " />";

	return $out;
}

sub hr
{
	return "<hr />";
}

sub input
{
}

sub br
{
	return "<br />";
}

sub list
{
	my ($this,$type,@items) = @_;
	
	my $out = $this->list_start($type);
	
	my $item;

	$out .= $this->list_item($_) foreach (@items);
	
	$out .= $this->list_end($type);

	return $out;
}

sub list_start
{
	my ($this,$type) = shift;
	my $tag;

	if	($type == OF_LIST_OD)	{ $tag = "ol"; }
	elsif	($type == OF_LIST_UN)	{ $tag = "ul"; }
	else {
		die "Unknown list type in list_end(); type: $tag";
	}
	
	return "<$tag>";
}

sub list_end
{
	my ($this,$type) = shift;
	my $tag;

	if	($type == OF_LIST_OD)	{ $tag = "ol"; }
	elsif	($type == OF_LIST_UN)	{ $tag = "ul"; }
	else {
		die "Unknown list type in list_end(); type: $tag";
	}
	
	return "</$tag>";
}

sub list_item
{
	return "<li>$_[1]</li>";
}

# print $of->header("hi")
# print $of->header("hi",4)
# print $of->header(size=>4,value=>5)
sub header
{
	my $this	= shift;
	my %prefs	= @_;
	
	if (@_ == 1)
	{
		%prefs = (value=>$_[0],size=>3);

	} elsif (@_ == 2 && $_[1] =~ /^\d+$/ && $_[0] ne "value") {

		%prefs = (value=>$_[0],size=>$_[1]);
	}

	my $size = $prefs{size};
	delete $prefs{size};
	
	my $value = $prefs{value};
	delete $prefs{value};
	
	my $out = "<h$size";

	my ($key,$val);
	$out .= qq{ $key="$val"} while ($key,$val) = each(%prefs);
	
	$out .= ">$value</h$size>";

	return $out;
}

sub emph
{
	return "<em>" . join('',@_[1..$#_]) . "</em>";
}

sub pre
{
	my $this = shift;
	return "<pre>" . $this->_cgi->escapeHTML(join('',@_)) . "</pre>";
}

sub code
{
	my $this = shift;
	return "<code>" . $this->_cgi->escapeHTML(join('',@_)) . "</code>";
}

sub strong
{
	return "<strong>" . join('',@_[1..$#_]) . "</strong>";
}

sub div
{
	my $this	= shift;
	my %prefs	= ref $_[0] eq "HASH" ? %{shift(@_)} : ();

	my $out = "<div";

	# Load default preferences

	my ($key,$val);
	$out .= qq{ $key="$val"} while ($key,$val) = each(%prefs);

	my $value = join('',@_);

	$out .= $value ? ">$value</div>" : " />";

	return $out;
}

sub img
{
	my ($this,%prefs) = @_;

	$prefs{alt}	= ""	unless exists $prefs{alt};
	$prefs{border}	= 0	unless exists $prefs{border};

	my $out = "<img";

	my ($key,$val);
	$out .= qq{ $key="$val"} while ($key,$val) = each(%prefs);

	$out .= " />";

	return $out;
}

sub email
{
}

return 1;
