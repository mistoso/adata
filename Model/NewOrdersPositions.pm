package Model::NewOrdersPositions;
use warnings;
use strict;

use Model;
use Model::SaleMod;
use Model::Saler; 
use Core::DB;
use Core::User;
use Data::Dumper;

our @ISA = qw/Model/;
sub db_table() {'new_orders_positions'};
sub db_columns(){ qw/id idOrder idMod price createDate getDate soldDate count state deleted idSaler buyPrice idOwner/};


sub floor_price(){
    use POSIX;
    my $self=shift;
    $self->{price} = floor($self->{price}); 
    $self->save();
}


sub sold(){

    my $self=shift;
    $self->{soldDate} = 'NOW()'; 
    $self->save();
}

sub product(){
    my $self=shift;
    $self->{'product'} 
  	  ||= Model::SaleMod->load($self->{'idMod'});
}

sub saler(){
    my $self=shift;
    $self->{'saler'} 
  	  ||= Model::Saler->load($self->{'idSaler'});
}

sub owner(){
    my $self=shift;
    $self->{'owner'} 
  	  ||= Core::User->load($self->{'idOwner'});
}

sub _before_save(){
    my $self=shift;
    return 1 unless $self->{'id'};
    my $s;     
    foreach my $key ($self->db_columns){
        next unless defined $self->{$key};
        next if (($key eq 'id')||($key eq 'idOrder')||($key eq 'idOwner')||($key eq 'idMod'));
        next if $self->{$key} eq '0000-00-00 00:00:00';
        if ($self->{"${key}NULL"}){
            $s .= " $key = ".undef;
        }elsif($self->{$key} =~ /^[A-Z_]+\(.*\)$/){
            $s .= " $key = ".$self->{$key};
        }elsif($self->{$key} ne ''){
            $s .= " $key = ".$self->{$key};
        }
    }
    my $user =Core::User->current();
    my $sth = $db->prepare('insert into new_orders_positions_history (idOrderPos,idOwner,changes) value (?,?,?)');
    $sth->execute($self->{'id'},$user->{'id'},$s);
    return 1;
}

sub order_sold(){
    my $self=shift;
    my $sold="1";
    my $sth = $db->prepare('select state from new_orders_positions where idOrder = ? and not deleted');
    $sth->execute($self->{'idOrder'});

    while (my $stat = $sth->fetchrow_array()){
        $sold = '0' if $stat ne 'sold';
    }

    if ($sold){
        my $sth = $db->prepare('update new_orders set soldDate = now() where id = ?');
        $sth->execute($self->{'idOrder'});
    }
    return 1;
}

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

1;
