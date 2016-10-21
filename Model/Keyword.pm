package Model::Keyword;
use warnings;
use strict;
use Model;
use DB;
use Data::Dumper;

our @ISA = qw/Model/;
sub db_table() {'keywords'};
sub db_columns(){ qw/id keyword weight_g weight_y/};

sub replace_y(){
	my $self = shift;
	my $buf = shift;
	
	foreach (@$buf){
		my $sths = $db->prepare('select id from keywords where keyword = ?');
		$sths->execute($_->{'1'});
		my $id = $sths->fetchrow_array();
		if ($id > 0 ){
			my $sthu = $db->prepare('update keywords set weight_y = ? where id = ? and keyword = ?');
			$sthu->execute($_->{'2'},$id,$_->{'1'});
		}else{
 			my $sth = $db->prepare('insert into keywords set keyword = ? , weight_y = ?');
			$sth->execute($_->{'1'},$_->{'2'});
		}		
	}
	return $self;
}

sub replace_g(){
	my $self = shift;
	my $buf = shift;

	foreach (@$buf){
		my $sths = $db->prepare('select id from keywords where keyword = ?');
		$sths->execute($_->{'1'});
		my $id = $sths->fetchrow_array();
		if ($id > 0 ){
			my $sthu = $db->prepare('update keywords set weight_g = ? where id = ? and keyword = ?');
			$sthu->execute($_->{'2'},$id,$_->{'1'});
		}else{
 			my $sth = $db->prepare('insert into keywords set keyword = ? , weight_g = ?');
			$sth->execute($_->{'1'},$_->{'2'});
		}		
	}
	return $self;
}

sub list(){
	my $self = shift;
	my $se = shift;
	my @buf;
	my $order = '' ;
	if ($se eq ('g' || 'y')){ $order = " order by weight_$se desc ";}
		my $sth = $db->prepare("select id from keywords $order ");
		$sth->execute();		
	while (my ($id) = $sth->fetchrow_array){
            push @buf,Model::Keyword->load($id);
        }
return \@buf;
}

sub delete(){
	my $self = shift;
	my $id = shift;
	my $sth = $db->prepare("delete from keywords where id = ?");
	$sth->execute($id);
	
	return $self;
}

sub searchl(){

	my $self = shift;
	my $words = shift;
	my $se = shift;
	my @buf;
	my @keys;
	my $where = '' ;
	my $order = '' ;
	if (($se eq "g") || ($se eq "y")){ $order = " order by weight_$se desc ";}
	@keys = split(',',$words);
	foreach (@keys){
		if ($where ne '') {$where .= ' AND '};
		$where .= ' keyword like "%'.$_.'%" ';
	} 
	my $sth = $db->prepare("select id from keywords where $where $order ");
	$sth->execute();		
	while (my ($id) = $sth->fetchrow_array){
            push @buf,Model::Keyword->load($id);
        }
	return \@buf;
}
sub _check_write_permissions(){1};
sub _check_columns_values(){1};

1;

