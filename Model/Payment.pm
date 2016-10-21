package Model::Payment;
use Model;
use Model::Currency;
use Core::DB;

our @ISA = qw/Model/;

sub db_table() {'payments'}
sub db_columns() { qw/id name description idCurrency isCashless isCredit isPublic/ }

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub currency(){
    my $self = shift;

    unless ($self->{_currency}){
	$self->{_currency} = Model::Currency->load($self->{idCurrency});
    }

    return $self->{_currency};
}

sub publicList(){
	my $self = shift;
	my @buf;

	my $sth = $db->prepare("SELECT id FROM payments WHERE isPublic = 1");	
    	$sth->execute();
	while (my $item = $sth->fetchrow_hashref){
		push @buf,Model::Payment->load($item->{id});
	}

	return \@buf;
}

1;
