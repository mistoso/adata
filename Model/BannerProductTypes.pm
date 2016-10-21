package Model::BannerProductTypes;
use warnings;
use strict;

use Model;
use DB;
use Data::Dumper;
use Model::BannerProducts;
use Core::Gallery;
use Cfg;

our @ISA = qw/Model/;

sub db_table() {'bannerProductTypes'};
sub db_columns() { qw/id name alias title idImage GalleryName isPublic deleted updated/};
sub db_indexes() {qw/id/};

sub _check_write_permissions(){
return 1;
}

sub _check_columns_values(){
    return 1;
}

sub product_list(){
    my $self = shift;
    my $idCategory = shift;
    my @buf;
    my $sth;

    if ($idCategory ne ''){
        $sth = $db->prepare("select bp.id from bannerProducts bp inner join salemods s on bp.idMod=s.id inner join category c on c.id=s.idCategory where bp.idType = ? and c.id = ? and not bp.deleted order by bp.isPublic desc,bp.sort");
        $sth->execute($self->{'id'}, $idCategory);
    }else{
        $sth = $db->prepare("select bp.id from bannerProducts bp where bp.idType = ? and not bp.deleted order by bp.isPublic desc,bp.sort");
        $sth->execute($self->{'id'});
    }
    while (my $id = $sth->fetchrow_array()){ push @buf,Model::BannerProducts->load($id); }
    return \@buf;
}

sub enum(){
    my $self = shift;
    unless ($self->{'enum'}){
        my $res;
        my $sth = $db->prepare("select count(*) from bannerProducts where idType = ? and not deleted");
        $sth->execute($self->{'id'});
        $res->{'all_enum'} = $sth->fetchrow_array();
        $sth = $db->prepare("select count(*) from bannerProducts where idType = ? and isPublic and not deleted");
        $sth->execute($self->{'id'});
        $res->{'public_enum'} = $sth->fetchrow_array();
        $self->{'enum'}= $res;
    }
    return $self->{'enum'};
}
###

sub image(){
    my $self = shift;
    $self->{_image} ||= Core::Gallery::Image::Default->new();
}

sub gallery(){
    my $self = shift;
    our $gpath = $cfg->{'PATH'}->{'gallery'};
    unless ($self->{_gallery}){
	    my $p = "icon/".$self->{alias};
	    $self->{GalleryName} = $p;
	    $self->save();
	    $gpath .= $p;
	    my $dir_exist = opendir(DIR,$gpath) or `mkdir -m777 -p $gpath`;
        closedir(DIR);    
        $self->{_gallery} = Core::Gallery->new($p);
    }
    return $self->{_gallery};
}
###



1;
