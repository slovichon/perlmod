package DBH;

$VERSION = 1.1;

use Exporter;
use DBI;

@ISA		= qw(Exporter);
@EXPORT		= qw(	DB_COL DB_ROW DB_ROWS DB_NULL
			SQL_REG SQL_WILD SQL_REGEX );

use strict;

use constant DB_COL	=> 1;
use constant DB_ROW	=> 2;
use constant DB_ROWS	=> 3;
use constant DB_NULL	=> 4;

use constant SQL_REG	=> 1;
use constant SQL_WILD	=> 2;
use constant SQL_REGEX	=> 3;

sub new
{
	my $driver	= "MySQL";
	my $host	= "localhost";
	my $port	= 3306;
	my $database	= "";
	my $username	= "";
	my $password	= "";

	return {"DBH::$driver"}->new("$host:$port",$database,$username,$password);
}

1;
