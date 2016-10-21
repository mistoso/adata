package Model::Saler;

use warnings;
use strict;

use DB;
use Core::User;

use Data::Dumper;

use Model::Category;
use Model::Brand;
use Model::SalerPrices;

our @ISA = qw/Model/;

sub db_table() {'salers'};
sub db_columns() { qw/id nostock name categoryList address phone email www info managers settings isVip/};

sub contacts(){
    my $self = shift;
    
    my $contacts = $self->{'address'}."".$self->{'phone'}."".$self->{'info'};

    return $contacts;
}

sub modprice(){
	my ($self,$modid) = @_;

	return undef unless $modid;
	unless ($self->{_prices}->{$modid}){
		my $sth = $db->prepare('SELECT id,price,DATE_FORMAT(updated,\'%d.%m.%y\'),uniqCode,instock,stockComment FROM salerprices WHERE idSaler = ? AND idSaleMod = ? order by updated desc limit 1');
		$sth->execute($self->{id},$modid);
		my $comm;
        my $id;
	($id,$self->{_prices}->{$modid},$self->{_uprices}->{$modid},$self->{_cprices}->{$modid},$self->{_stprices}->{$modid},$comm) = $sth->fetchrow_array;

        ################# fix  that clean salerprices #####################################################
        my $dsth = $db->prepare('delete from salerprices where idSaler = ? AND idSaleMod = ? AND id != ?');
        $dsth->execute($self->{id},$modid,$id);
        ###################################################################################################
		$self->{_stprices}->{$modid} = $comm if $comm;
        $self->{stprice_id} = $id;
	}

	return $self->{_prices}->{$modid} ;
}

sub delete(){
	my $self = shift;
	$self->{'deleted'} = 1;
	$self->save();

    my $sth = $db->prepare('update salerprices set price = 0 where idSaler = ?');
    $sth->execute($self->{'id'});

    return 1;
}	
sub modpriceupdated(){
	my ($self,$modid) = @_;

	unless ($self->{_uprices}->{$modid}){
		my $sth = $db->prepare('SELECT DATE_FORMAT(updated,\'%d.%m.%y\') FROM salerprices WHERE idSaler = ? AND idSaleMod = ?  order by updated desc limit 1');
		$sth->execute($self->{id},$modid);
		($self->{_uprices}->{$modid}) = $sth->fetchrow_array;
	}

	return $self->{_uprices}->{$modid};
}

sub modpriceuniq(){
	my ($self,$modid) = @_;

	unless ($self->{_cprices}->{$modid}){
		my $sth = $db->prepare('SELECT uniqCode FROM salerprices WHERE idSaler = ? AND idSaleMod = ?  order by updated desc limit 1');
		$sth->execute($self->{id},$modid);
		($self->{_cprices}->{$modid}) = $sth->fetchrow_array;
	}

	return $self->{_cprices}->{$modid};
}

sub modstock(){
	my ($self,$modid) = @_;

	unless ($self->{_stprices}->{$modid}){
		my $sth = $db->prepare('SELECT instock,stockComment FROM salerprices WHERE idSaler = ? AND idSaleMod = ?  order by updated desc limit 1');
		$sth->execute($self->{id},$modid);
		my ($stock,$comm) = $sth->fetchrow_array;
		$self->{_stprices}->{$modid} = $comm || $stock;
	}

	return $self->{_stprices}->{$modid};
}


sub catprices(){
    my ($self, $cid , $brand) = @_;
    
    return undef unless $cid;
    unless ($self->{_catprices}->{$cid}){
        my $q = '   SELECT salerprices.id 
                    FROM salemods,salerprices
			        WHERE salemods.idCategory = ? AND salerprices.idSaler = ? AND salerprices.idSaleMod = salemods.id';
		$q .= ' AND salemods.idBrand = ?' if $brand;
        $q .= ' order by salerprices.updated ';
		my $sth = $db->prepare($q);
		$brand ? $sth->execute($cid,$self->{'id'},$brand) : $sth->execute($cid,$self->{'id'});
		while (my ($id) = $sth->fetchrow_array){
			push @{$self->{_catprices}->{$cid}}, Model::SalerPrices->load($id);
		}
	}
	
	return $self->{_catprices}->{$cid};
}

sub modsubprice(){
	my ($self,$model) = @_;

	return $model->price - $self->modprice($model->{id});
}

sub categorys(){
	my $self = shift;

	unless ($self->{_categorys}){
		my $sth = $db->prepare('select distinct(sm.idCategory) as id,c.name,SUM(IF(sp.price > 0,1,0)) as count from salemods sm inner join salerprices sp on sm.id = sp.idSaleMod inner join category c on c.id = sm.idCategory where sp.idSaler = ? group by sm.idCategory order by c.name');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){
		push @{$self->{_categorys}}, $item;
	}}

	return $self->{_categorys};
}
sub addCategory(){
    my $self = shift;
    my $cat = shift;

    unless ($self->isinCategory($cat)){
        $self->{'categoryList'} .= ",$cat";
        $self->save();
    }
}
sub isinCategory(){
	my ($self,$id ) = @_;

	foreach my $cid (split /,/, $self->{categoryList}){
		return 1 if $cid == $id;
	}

	return 0;
}

sub _check_write_permissions(){
	my $user = Core::User->current();

	return 1 if $user->isInGroup('manager','root');
	return 0;
}

sub _check_columns_values(){
	my $self = shift;

	my $q = 'SELECT count(*) from users where name = ?';
	my $sth = $db->prepare($q);
	$sth->execute($self->{name});
	my ($res) = $sth->fetchrow_array;
	if($res < 1){
		unless ($self->{idUser}){
			my $user = Core::User->new({
				name => $self->{name},
				type => 'saler',
			});
			$user->save();
			$self->{idUser} = $user->{id};
		}
	}

	return 1;
}

sub setCategoryList(){
	my ($self,$args) = @_;
	my @buf;
    foreach my $key (keys %$args){
		my ($id) = ($key =~ /^c(\d+)$/) or next;
		push @buf, $id;
	}
	$self->{categoryList} = join ',',@buf;  
}

sub user(){
	my $self = shift;

	unless ($self->{_user}){
		$self->{_user} = Core::User->load($self->{idUser});
	}

	return $self->{_user};
}

sub vipSalerCat(){
    my $self = shift;

    my $msth = $db->prepare('update salerprices set vip = ? where idSaler = ?');
    $msth->execute($self->{'isVip'},$self->{'id'});

    return 1;
}

sub getBrandsDiscont(){
	my $self = shift;

	my $sth = $db->prepare('select b.name,sbd.id,sbd.idBrand,discont from salerprices_brand_discont as sbd inner join brands as b on sbd.idBrand=b.id  where idSaler = ?');
	$sth->execute($self->{id});
	while (my $item = $sth->fetchrow_hashref){
		push @{$self->{brandsDiscont}}, $item;
	}
	return $self->{brandsDiscont};
}

1;
