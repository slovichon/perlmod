package HTTP::Session;

$VERSION = 0.92;

use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use File::Copy;
use Exporter;
use Timestamp;
use FreezeThaw qw/freeze thaw/;

use constant SESS_LEN 		=> 32;
use constant SESS_DEF_FILE	=> "/usr/local/lib/htsessions";
use constant SESS_DEF_TIMEOUT	=> 60 * 20; 			# 20 minutes

use strict;
{
	# Generates a new, unique session identifier
	my $_gen_sess_id =
	sub
	{
		my $file 	= shift;
		my @chars 	= ("a" .. "z","A" .. "Z",0 .. 9);
		my $sess_id 	= $chars[int rand @chars] for (1 .. 16);

		return &{$_valid_sess_id($sess_id,$file)} ? &{$_gen_sess_id}($file) : $sess_id;
	};
	
	# Validates a session identifier
	my $_valid_sess_id =
	sub
	{
		my ($sess_id,$file,$r_data) = shift;
		my ($valid,$line,$r_session);
		local *SESS_FH;

		open SESS_FH,"< $file" or &{$_die}("Cannot open $file: $!");
		
		while (defined($line = <SESS_FH>))
		{
			chomp $line;

			eval
			{
				($r_session) = thaw($line);
				
			} or &{$_die}("thaw() failed: $@");

			if
			(
				$r_session->{id} eq $sess_id &&
				$r_session->{timestamp} > time() + $r_session->{timeout}
			)
			{ 
				$r_data	= $r_session->{data} if defined $r_data;
				$valid 	= 1;
				last;
			}
		}

		close SESS_FH;

		return $valid;
	};

	# Wrappped die()
	my $_die = 
	sub
	{
		die shift;
	};

	my $_was_dropped;

	# Removes a session
	my $_remove_session =
	{
		my ($file,$sess_id) = @_;
		my ($temp,$line,$r_session) = (tmpnam());
		local (*SESS_FH,*TEMP);

		open TEMP,"> $temp"	or &{$_die}("Cannot open $temp: $!");
		open SESS_FH,"< $file"	or &{$_die}("Cannot open $file: $!");

		while (defined($line = <SESS_FH>))
		{
			chomp $line;

			eval
			{
				($r_session) = thaw($line);
				
			} or &{$_die}("thaw() failed: $@");

			print TEMP $line,$/ unless $r_session->{"id"} eq $sess_id;
		}

		close SESS_FH;
		close TEMP;

		rename $tmp,$file or &{$_die}("Cannot move $tmp to $file: $!");

		return;
	}

	sub new
	{
		my ($pkg,$sess_id,%cond) = @_;
		my ($load,$r_session) = (0,{});
		
		$cond{file} 	||= SESS_DEF_FILE;
		$cond{timeout}	||= SESS_DEF_TIMEOUT;
		
		# Assume new session is being created if
		# no argued session identifier; else, the
		# old session will be loaded
		unless (defined $sess_id && &{$_valid_sess_id}($sess_id,$cond{file},$r_data))
		{
			$sess_id 	= &{$_gen_sess_id}($cond{file});
		} else {
			$load 		= 1;
		}

		my $obj = 	bless
				{
					id		=> $sess_id,
					data		=> $r_data,
					file		=> $cond{file},
					timeout		=> $cond{timeout},
					timestamp	=> time()
				
				},ref($pkg) || $pkg;

		# If actually an object, load object's data
		# Note: this can be monstrously dangerous
		$obj->{data} = $pkg->{data} if ref($pkg);

		return $obj;
	}

	sub DESTROY
	{
		# If they dropped the session, there's no
		# point in saving it
		return if $_was_dropped;

		my $obj = shift;
		my ($r_session,$line,$swt,$temp);
		local *SESS_FH;
		
		$temp = tmpnam();
		
		# Save data
		open SESS_FH,"< $obj->{file}" 		or &{$_die}("Cannot open $obj->{file}: $!");
		open TEMP,"< $tmp"			or &{$_die}("Cannot open $tmp: $!");
		
		while (defined($line = <SESS_FH>))
		{
			chomp;

			eval
			{
				($r_session) = thaw($line);

			} or &{$_die}("thaw() failed: $@");

			if (!$swt && $r_session->{"id"} eq $obj->{"id"})
			{
				$line 	= freeze($obj);
				$swt++;
			}
			
			print TEMP $line,$/;
		}

		# New sessions aren't going to have existing entries
		print TEMP freeze($obj),$/ unless $swt;

		close TEMP;
		close SESS_FH;

		rename $tmp,$obj->{file}	or &{$_die}("Cannot move $tmp to $obj->{file}: $!");
	}

	sub store
	{
		my ($obj,$key,$value) = @_;

		$obj->{data}{$key} = $value;

		return;
	}

	sub retrieve
	{
		my ($obj,$key) = @_;

		return $obj->{data}{$key};
	}

	sub drop
	{
		my $obj = shift;
		
		&{$_remove_session}($obj->{file},$obj->{id});

		$_was_dropped = 1;

		return;
	}
}

return 1;
