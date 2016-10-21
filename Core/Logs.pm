package Core::Logs;
use Core::DB;
use strict;

sub new(){
    my $class = shift;
    my $self = bless { },$class;
    return $self;
}

sub main_log_front(){
    my ($self,$REMOTE_ADDR,$HTTP_REFERER,$HTTP_HOST,$REQUEST_URI) = @_;
    my $sth = $db->prepare("insert into logs_front set ip = INET_ATON(?), referer = ?, url = ?, date = NOW();");
    $sth->execute($REMOTE_ADDR || 0,$HTTP_REFERER || 0,$HTTP_HOST."".$REQUEST_URI || 0);
}

1;
