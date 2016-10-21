package Core::AuthAccess;
use Cfg;

use Apache2::Const qw/OK NOT_FOUND/;
use Apache2::RequestRec;
use Apache2::Connection;

sub handler {
    my $r = shift;
    my $ip = $r->connection->remote_ip();

    foreach $key ( keys %{$cfg->{ip_wite_list}} ) 
    {
    	if ($ip =~ /$key/) 
    	{
                return OK;
    	}
    }
    return NOT_FOUND;
}

1;
