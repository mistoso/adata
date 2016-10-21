package DB;

use latest;
use Apache::DBI;
use DBI;
use Cfg;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT );
    @ISA    = qw(Exporter);
    @EXPORT = qw( $db );
    our $db  = DBI->connect('DBI:mysql:database='.$cfg->{DB}->{name}.';hostname=localhost',$cfg->{DB}->{user},$cfg->{DB}->{pass},{RaiseError=>1,AutoCommit=>1});
}

1;

