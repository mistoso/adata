package Model::MailQuery;

use Model;
use Core::DB;

our @ISA = qw/Model/;
sub db_table() {'mail_query'};
sub db_columns(){ qw/message error/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub delete(){
	my $self = shift;
	my $sth = $db->prepare('delete from mail_query where message = ?');
	$sth->execute($self->{'message'});

}

1;
