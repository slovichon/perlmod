package HTTP::Sessions;

use CGI;
use File::Copy;
use Exporter;
use Timestamp;

@EXPORTER = ('get','put');




$HTTP::Sessions::VERSION	= ".9b";
$HTTP::Sessions::Timeout	= 60 * 60; # Default: 1 hour
$HTTP::Sessions::SessID;

my ($savefile)			= "/usr/www/sessions.dat";
my ($tempfile)			= "/usr/www/sessions.tmp";

sub new
{
	my ($SessID) = @_;
	my (%session,$pair,$key,$value)

	open(FH,"<$savefile") || die($!);
	while(<FH>)
	{
		chomp;
		foreach $pair (split(/&/))
		{
			($key,$value) = split(/=/,$pair);
			$session{CGI->unescape($key)} = CGI->unescape($value);
		}
		if ($session{"SessID"} eq $SessID)
		{
			# Check if the session timeout
			# is still valid.
			if ()
			{
				last;
			} else {
				$HTTP::Sessions::SessID = $SessID;
				put({'timeout' => get_timestamp()});
				return;
			}
		}
		%session = undef;
	}
	close(FH);

	# Assume session id was not caught by the if
	# and therefore does not exist.

	$SessID = &GenerateSessID();
	$HTTP::Sessions::SessID = $SessID;

	open(FH,">>$savefile") || die($!);
	print FH "SessID=$SessID&timeout=" . get_timestamp() . "\n";
	close(FH);
	return;
}

sub GenerateSessID
{
	my (@chars) = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9);
	my ($SessID,%session);

	for (1 .. 28)
	{
		$SessID .= $chars[int rand length(@chars)];
	}

	open(FH,"$savefile") || die($!);
	while(<FH>)
	{
		chomp;
		foreach $pair (split(&))
		{
			($key,$value) = split(/=/,$pair);
			$session{CGI->unescape($key)} = CGI->unescape($value);
		}
		if ($session{"SessID"} eq $SessID)
		{
			close(FH);
			return(&GenerateSessID());
		}
		$session = undef;
	}
	close(FH);

	return($SessID);
}

sub put
{
	my ($r_hash) = @_;
	my ($varstr,%session,$pair,$key,$value,$existing_session);

	open(RFH,"<$savefile")	|| die($!);
	open(WFH,">$tempfile")	|| die($!);
	while (<FH>)
	{
		chomp;
		next if (/^\s*$/);
		foreach $pair (split(/&/))
		{
			($key,$value) = split(/=/,$pair);
			$session{CGI->unescape($key)} = CGI->unescape($value);
		}
		if ($session{"SessID"} eq $HTTP::Sessions::SessID)
		{
			$existing_session++;
			@session{keys %$r_hash} = values %$r_hash;
		}
		foreach $key (keys %session)
		{
			$varstr .= CGI->escape($key) . "=" . CGI->escape($session{$key}) . "&";
		}
		$varstr		=~ s/&$/\n/;
		print WFH $varstr;
		$session	= undef;
		$varstr		= undef;
	}
	close(RFH);

	if (!$existing_session)
	{
		foreach (keys %$r_hash)
		{
			$varstr .= CGI->escape($_) . "=" . CGI->escape($r_hash->{$_}) . "&";
		}
		$varstr =~ s/&$/\n/;
		print WFH $varstr;

	} elsif ($existing_sessions > 1) {

		close(WFH);

		open(RFH,"<$tempfile") || die($!);
		open(WFH,">$savefile") || die($!);
		while (<RFH>)
		{
			chomp;
			next if (/^\s*$/);
			foreach $pair (split(/&/))
			{
				($key,$value) = split(/=/,$pair);
				$session{CGI->unescape($key)} = CGI->unescape($value);
			}
			unless ($session{"SessID"} eq $HTTP::Sessions::SessID)
			{
				foreach $key (keys %session)
				{
					$varstr .= CGI->escape($key) . "=" . CGI->escape($session{$key}) . "&";
				}
				$varstr =~ s/&$/\n/;
				print WFH $varstr;
				$varstr = undef;
			}
			$session = undef;
		}
		close(WFH);
		close(RFH);

		die("SessionID Error: Session ID has been duplicated!");
	}
	close(WFH);
}

sub get
{
	my ($r_array) = @_;
	my (%session,$pair,$key,$value,@rarray);

	open(FH,"<$savefile") || die($!);
	while(<FH>)
	{
		chomp;
		foreach $pair (split(/&/))
		{
			($key,$value) = split(/=/,$pair);
			$session{CGI->unescape($key)} = CGI->unescape($value);
		}
		last if ($session{"SessID"} eq $HTTP::Sessions::SessID);
		%session = undef;
	}
	close(FH);

	return(@session{@$r_array});
}

return(1);