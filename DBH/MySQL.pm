package DBH::MySQL;

$VERSION = 1.4;

use DBI;

use strict;

use constant DB_COL	=> 1;
use constant DB_ROW	=> 2;
use constant DB_ROWS	=> 3;
use constant DB_NULL	=> 4;

use constant SQL_REG	=> 1;
use constant SQL_WILD	=> 2;
use constant SQL_REGEX	=> 3;

{
	my %saved;

	sub new
	{
		my ($pkg,$db,$user,$pass)	= @_;

		if
		(
			keys(%saved)				&&
			#$saved{host}		eq $host	&&
			$saved{user}		eq $user	&&
			$saved{pass}		eq $pass	&&
			$saved{database}	eq $db
		)
		{
			return $saved{handle};
		}

		my $link_id			= DBI->connect("DBI:mysql:$db",$user,$pass);
		my $obj				=	bless
							(
								{
									"dbh"		=> $link_id,
									"sth"		=> undef,
									"rows"		=> -1,
								},
								$pkg
							);

		%saved =	(
			#		'host'		=> $host,
					'user'		=> $user,
					'pass'		=> $pass,
					'database'	=> $db,
					'handle'	=> $obj,
				);

		$obj->handle_error("Cannot connect to database; database=$db; username=$user; password=YES") if $DBI::errstr;

		return $obj;
	}
}

sub handle_error
{
	my ($obj,$msg) = @_;

	$msg .= "; Database error: $DBI::errstr";

#	$obj->DESTROY();

	common::handle_fatal_error($msg);
}

sub query
{
	my ($obj,$stmt,$type) = @_;

	$obj->{"sth"} = $obj->{"dbh"}->prepare($stmt)	or $obj->handle_error("Cannot prepare query; stmt=$stmt");

	$obj->{"sth"}->execute()			or $obj->handle_error("Cannot execute query; stmt=$stmt");

	if ($type == DB_COL)
	{
		my $field = ($obj->{"sth"}->fetchrow)[0];
		$obj->{"sth"}->finish();
		return $field;

	} elsif ($type == DB_ROW) {

		my %row = ();
		@row{@{$obj->{"sth"}->{"NAME"}}} = $obj->{"sth"}->fetchrow;
		$obj->{"sth"}->finish();
		return %row;

	} elsif ($type == DB_ROWS) {

		$obj->{"rows"} = $DBI::rows;
		return $DBI::rows;

	} elsif ($type == DB_NULL) {

		my $rows = $DBI::rows;
		$obj->{"sth"}->finish();
		return $rows;
	} else {
		$obj->handle_error("Invalid DBH::query() type; type: $type");
	}
}

sub fetch_row
{
	my $obj = shift;
	my %row = ();

	unless ($obj->{"rows"}--)
	{
		$obj->{"sth"}->finish();
		return;
	}

	@row{@{$obj->{"sth"}->{"NAME"}}} = $obj->{"sth"}->fetchrow;

	return %row;
}

sub prepare_str
{
	my ($obj,$str,$type) = @_;

	$type == SQL_REG	and $str = s/['"\\]/\\$0/g;
	$type == SQL_WILD	and $str = s/['"\\_%]/\\$0/g;
	$type == SQL_REGEX	and $str = s/['"\\^\$()\[\]{}+*?.]/\\$0/g;

	return $str;
}

sub DESTROY
{
	my $obj	= shift;

#	$obj->{"dbh"}->disconnect();

	return;
}

sub last_insert_id
{
	my $obj = shift;

	return $obj->{"dbh"}->func("_InsertID");
}

1;
