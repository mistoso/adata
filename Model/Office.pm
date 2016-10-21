package Model::Office;

use Model;
use DB;
use Core::User;
use Model::Office::Schedule;
use Model::Office::Phones;
our @ISA = qw/Model/;

sub db_table() {'offices'};
sub db_columns() {qw/ id name shortName address email phone icq host/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


sub list(){
    my $sth = $db->prepare('SELECT id FROM offices');
    $sth->execute();
    my @buf;

    while (my ($id) = $sth->fetchrow_array){ push @buf, Model::Office->load($id); }

    return \@buf;
}

sub schedule(){
    my $self = shift;
    unless ($self->{'schedule'}){
  
        my $sth = $db->prepare('SELECT id FROM officeSchedule where idOffice = ? and not deleted');
        $sth->execute($self->{'id'});
  
        my @buf;
  
        while (my ($id) = $sth->fetchrow_array){ push @buf, Model::Office::Schedule->load($id); }
        $self->{'schedule'} = \@buf;
    }
    return $self->{'schedule'};
}

sub phones(){
    my $self = shift;
    $self->{'phones'} ||= Model::Office::Phones->list();
}

1;

