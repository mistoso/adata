package DB;

use strict;

use Apache::DBI;
use DBI;
use Cfg;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );
    @ISA    = qw(Exporter);
    @EXPORT = qw( $db );
#    our $db  = DBI->connect("DBI:mysql:".$cfg->{DB}->{name}.":localhost;mysql_local_infile=1;mysql_multi_results=1", $cfg->{DB}->{user}, $cfg->{DB}->{pass},{PrintError => 1,AutoCommit => 1,RaiseError => 1});

     our $db  = DBI->connect("DBI:mysql:".$cfg->{DB}->{name}.":localhost;mysql_local_infile=1;mysql_multi_results=1", $cfg->{DB}->{user}, $cfg->{DB}->{pass},{PrintError => 1,AutoCommit => 1,RaiseError => 1});

}

1;

