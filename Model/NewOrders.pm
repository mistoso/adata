package Model::NewOrders;

use warnings;
use strict;

use Model;
use DB;
use Model::NewOrdersPositions;
use Data::Dumper;

our @ISA = qw/Model/;
sub db_table() {'new_orders'};
sub db_columns(){ qw/id clientPhone clientName clientAddress clientEmail updated deleted currencyValue deliveryTime deliveryDate comment createDate/};

sub _check_columns_values(){1};

sub _check_write_permissions(){1};

sub list_by_state(){
    my $self    = shift;
    my $state   = shift;
    my $order_by= shift;
    my $desc    = shift || 'desc';
    #my $limit   = shift || '50,0';
    my $res = {};
    my $q = "select distinct(o.id) from new_orders as o inner join new_orders_positions as op on o.id = op.idOrder INNER JOIN salemods sm ON op.idMod = sm.id where not op.deleted and not o.deleted ";
#    my $sth  = $db->prepare('select distinct(o.id) from new_orders as o inner join new_orders_positions as op on o.id = op.idOrder INNER JOIN salemods sm ON op.idMod = sm.id where not op.deleted and state = ? and not o.deleted ORDER BY o.createDate desc, op.idSaler;');
    $q .= " and state ='".$state."'" if $state ne '';
    $order_by .= "," if $order_by; 
    $q .= " order by ".$order_by."o.createDate ".$desc;
    my $sth = $db->prepare($q);
    $sth->execute();
    while (my ($id) = $sth->fetchrow_array){
	    push @{$res->{'list'}},Model::NewOrders->load($id);
    }
    return $res;
}
sub positions(){
    my $self  = shift;
    unless ($self->{positions}){
        my $sth  = $db->prepare('select id from new_orders_positions where idOrder = ? and not deleted');
        $sth->execute($self->{'id'});
        while (my $id = $sth->fetchrow_array){
            push @{$self->{positions}},Model::NewOrdersPositions->load($id);
        }
    }
    return $self->{positions};
}

sub allPosPrice(){
    my $self  = shift;
    $self->{summ} = 0;
    return 0 if $self->positions() eq '';
    for (@{$self->positions()}){ 
       my $sum = $_->{price} * $_->{count};
       $self->{summ} = $self->{summ} + $sum;
    }
    return $self->{summ};
}

sub del_positions(){
    my $self  = shift;
    for (@{$self->positions()}){ 
       $_->delete();
    }
}


sub sold(){
    my $self=shift;
    my $sold="1";
 
    my $sth = $db->prepare('select state from new_orders_positions where idOrder = ? and not deleted');
    $sth->execute($self->{'id'});

    while (my $stat = $sth->fetchrow_array()){
        $sold = '0' if $stat ne 'sold';
    }

    if ($sold){
        my $sth = $db->prepare('update new_orders set soldDate = now() where id = ?');
        $sth->execute($self->{'id'});
    }
    return 1;
}
1;
