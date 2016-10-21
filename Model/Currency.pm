package Model::Currency;
use Model;
use DB;
use Data::Dumper;

our @ISA = qw/Model/;
sub db_table() {'currency'}
sub db_columns() {qw/ id name comment value symbol code in_use isPublic/};

sub list(){
    my $self = shift;
    
    my $sth = $db->prepare('SELECT id FROM currency WHERE NOT deleted');

    $sth->execute();
    my @buf;
    while (my ($id) = $sth->fetchrow_array){
	push @buf, Model::Currency->load($id);
    }
    return \@buf;
}

sub front_currency(){
    my $self = shift;
    
    my $sth = $db->prepare('SELECT id FROM currency WHERE NOT deleted and id != 2');
    $sth->execute();
    my @buf;
    while (my ($id) = $sth->fetchrow_array){
	    push @buf, Model::Currency->load($id);
    }
    
    return \@buf;
}


sub usd_currency(){
    my $self = shift;
    
    my $sth = $db->prepare('SELECT value FROM currency WHERE NOT deleted and id = 1');
    $sth->execute();
    my ( $value ) = $sth->fetchrow_array;
    return $value;
}

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub cons_currency(){
    my $self = shift;
    my ( $currencyValue, $idPayment ) = @_;
    my $sth = $db->prepare('UPDATE orders SET currencyValue = ? WHERE state <> "sold" AND currencyValue IS NULL AND idPayment = ?');
    my $res = $sth->execute($currencyValue,$idPayment);
    return $res;
}

1;
