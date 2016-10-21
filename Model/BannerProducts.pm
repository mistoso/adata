package Model::BannerProducts;
use warnings;
use strict;

use Model;
use Core::DB;
use Data::Dumper;
use Model::SaleMod;

our @ISA = qw/Model/;

sub db_table() {'bannerProducts'};
sub db_columns() { qw/id idMod idType date_to sort isPublic deleted updated/};
sub db_indexes() {qw/id/};

sub _check_write_permissions(){
return 1;
}

sub _check_columns_values(){
    return 1;
}

sub product(){
    my $self = shift;
    $self->{'product'} ||= Model::SaleMod->load($self->{'idMod'});
    return $self->{'product'};
}

sub get_by_type_and_mod(){
    my $self = shift;
    my $sth = $db->prepare("select id from bannerProducts where idMod = ? and idType = ?  ");
    $sth->execute($self->{'idMod'},$self->{'idType'});
    my $id = $sth->fetchrow_array();

    $self = Model::BannerProducts->load($id);
    $self->{'deleted'} = 0;
    $self->{'isPublic'} = 1;
    return $self;

}

sub add_group(){
	my $self = shift;
	my $res = shift;
	my $set = shift;
	my $dt = "?";
	foreach (@$res){
		if ($set->{'enum'} eq 'name'){
			my $mod = Model::SaleMod->load($_->{'1'},'name');
			$_->{'1'} = $mod->{'id'};	
		} elsif ($set->{'enum'} eq 'saler'){
			$_->{'1'} =~ s/\*/x/gm;
			$_->{'1'} =~ s/\)//gm;
			$_->{'1'} =~ s/\(//gm;
                	$_->{'1'} =~ s/\.//gm;
			$_->{'1'} =~ s/\'//gm;
			$_->{'1'} =~ s/\"//gm;
			$_->{'1'} =~ s/\_//gm;
			$_->{'1'} =~ s/\s*?//gm;
			$_->{'1'} =~ s/\\//gm;
			$_->{'1'} =~ s/\t/ /gm;
			$_->{'1'} =~ s/\ +/ /gm;
			$_->{'1'} =~ s/\ //gm;
			my $sth = $db->prepare("select idSaleMod from salerprices where uniqCode = ? ");
			$sth->execute($_->{'1'});		
			$_->{'1'} = $sth->fetchrow_array();		
		}
		next unless $_->{'1'}; 
		$_->{'2'} = "DATE_ADD(CURDATE(),INTERVAL 60 MONTH)" unless (exists $_->{'2'}); 
		my $sth = $db->prepare("replace into bannerProducts set idMod = ? , idType = ? ,date_to = $_->{'2'},isPublic = 1  ");
		$sth->execute($_->{'1'},$set->{'idBanner'});		
	}
	return $self;
}
sub add_group_old(){
	my $self = shift;
	my $res = shift;
	
	foreach (@$res){
		if ($_->{'4'}){
			my $mod = Model::SaleMod->load($_->{'4'},'name');
			$_->{'3'} = $mod->{'id'};	
		} elsif ($_->{'5'}){
			$_->{'5'} =~ s/\*/x/gm;
			$_->{'5'} =~ s/\)//gm;
			$_->{'5'} =~ s/\(//gm;
                	$_->{'5'} =~ s/\.//gm;
			$_->{'5'} =~ s/\'//gm;
			$_->{'5'} =~ s/\"//gm;
			$_->{'5'} =~ s/\_//gm;
			$_->{'5'} =~ s/\s*?//gm;
			$_->{'5'} =~ s/\\//gm;
			$_->{'5'} =~ s/\t/ /gm;
			$_->{'5'} =~ s/\ +/ /gm;
			$_->{'5'} =~ s/\ //gm;
			my $sth = $db->prepare("select idSaleMod from salerprices where uniqCode = ? ");
			$sth->execute($_->{'5'});		
			$_->{'3'} = $sth->fetchrow_array();
			
		}
		my $sth = $db->prepare("replace into bannerProducts set idMod = ? , idType = ? ,date_to = ?,isPublic = 1  ");
		$sth->execute($_->{'3'},$_->{'1'},$_->{'2'}||"DATE_ADD(CURDATE(),INTERVAL 60 MONTH)");		
	}
	return 1;
}




1;
