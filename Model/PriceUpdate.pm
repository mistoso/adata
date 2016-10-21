package Model::PriceUpdate;
use Model;
use Core::User;
use Model::Saler;
our @ISA = qw/Model/;

sub db_table() {'salerprices_updates'};

sub operator(){
    my $self = shift;
    $self->{_operator} ||= Core::User->load($self->{idOperator});
}

sub saler(){
    my $self = shift;
    $self->{_saler} ||= Model::Saler->load($self->{idSaler});
}
1;
