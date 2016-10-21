package Banner;

use warnings;
use strict;
use Core::DB;

use Model::SaleMod;
use Model::Brand;
use Model::BannerProductTypes;
use Model::APRPages;

sub new(){
    my $class = shift;
    bless {},$class;
}

sub showcase(){
    my ($self, $group, $limit, $order) = @_;
    my $limit_string = ' ';
    if( $limit )                  { $limit_string = "LIMIT ".$limit; }
    if( $order ){ $order = "ORDER BY ".$order; }else{ $order = " ORDER BY bp.sort "; }
    my @buf;        
    my $sql = "SELECT sm.id FROM category c INNER JOIN salemods sm ON c.id = sm.idCategory INNER JOIN bannerProducts bp ON bp.idMod = sm.id
            WHERE sm.price > 0 and not sm.deleted and sm.isPublic and bp.isPublic  and bp.idType = 1 and sm.idImage > 0
		       ".$order." ".$limit_string;
    #warn "\n\n\n\n\n $sql \n\n\n\n\n";
    my $sth = $db->prepare("$sql");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf, Model::SaleMod->load($item->{id}),
    }
    return \@buf;
}

sub salemod_get_part_in(){
    my ($self,$id) = @_;
    my @buf;
    my $sth = $db->prepare("select bpt.id from bannerProductTypes bpt inner join bannerProducts bp on bp.idType = bpt.id inner join salemods s on s.id = bp.idMod where not bp.deleted and bp.isPublic and s.id = ? ");
    $sth->execute($id);
    while (my $item = $sth->fetchrow_hashref){
        #next unless (($item->{id} eq '3' )||($item->{id} eq '4'));
        push @buf, Model::BannerProductTypes->load($item->{id}),
    }
    
    return \@buf;
}

sub get_banner_type_by_id(){
    my ($self,$id) = @_;
    my $banner = Model::BannerProductTypes->load($id);
    return $banner;
}

sub product_banners(){
    my $self=shift;
    return Model::BannerProductTypes->list();;
}

sub recomended_products(){
    my ($self, $type, $pcategory_id, $category_id, $brand_id, $group, $limit, $order) = @_;
    my $category_string;
    my $brand_string;
    my $btype;
    my $group_string = ' sm.id';
    my $limit_string = ' limit 15';
    if( $pcategory_id =~ /^\d+$/ ){ $category_string = ' AND c.idParent = '.$pcategory_id; }
    if( $category_id  =~ /^\d+$/ ){ $category_string = " AND c.id = ".$category_id;    }
    if( $brand_id     =~ /^\d+$/ ){ $brand_string = " AND b.id = ".$brand_id;   }
    if( $group eq 'category' )    { $group_string = " c.id"; }
    if( $group eq 'brands')       { $group_string = " b.id"; }
    if( $group eq 'salemods')     { $group_string = " sm.id"; }
    if( $limit )                  { $limit_string = "LIMIT ".$limit; }
    if(!$type)                    { return undef;}else{ $btype= "bp.idType = $type ";}

    if( $order ){ $order = "ORDER BY ".$order; }else{ $order = "ORDER BY bp.sort"; }
    my @buf;
    my $sql = "(SELECT sm.id
         FROM category c INNER JOIN salemods sm ON c.id = sm.idCategory 
       INNER JOIN brands b ON b.id = sm.idBrand 
       INNER JOIN bannerProducts bp ON bp.idMod = sm.id
            WHERE sm.price > 0 and bp.isPublic and not bp.deleted and sm.isPublic 
            and ".$btype."
                ".$category_string."
                ".$brand_string."
               GROUP BY ".$group_string."  
               ".$order." 
        ) UNION DISTINCT  (
        SELECT sm.id
         FROM category c INNER JOIN salemods sm ON c.id = sm.idCategory 
       INNER JOIN brands b ON b.id = sm.idBrand 
       INNER JOIN bannerProducts bp ON bp.idMod = sm.id
            WHERE sm.price > 0 and bp.isPublic and not bp.deleted and sm.isPublic 
            and ".$btype."
                ".$brand_string."
               GROUP BY ".$group_string.")"
        .$limit_string;
	warn "\n\n\n\n\n $sql \n\n\n\n\n";
    my $sth = $db->prepare("$sql");
    $sth->execute();
    while (my $id = $sth->fetchrow_array){
        push @buf, Model::SaleMod->load($id),
    }
    return \@buf;
}

sub recomended_products_unlim(){
    my ($self, $type, $pcategory_id, $category_id, $brand_id, $group, $limit, $order) = @_;

    my $category_string;
    my $brand_string;
    my $btype;

    my $group_string = ' sm.id';
    my $limit_string = ' ';
    if( $pcategory_id =~ /^\d+$/ ){ $category_string = ' AND c.idParent = '.$pcategory_id; }
    if( $category_id  =~ /^\d+$/ ){ $category_string = " AND c.id = ".$category_id;    }
    if( $brand_id     =~ /^\d+$/ ){ $brand_string = " AND b.id = ".$brand_id;   }
    if( $group eq 'category' )    { $group_string = " c.id"; }
    if( $group eq 'brands')       { $group_string = " b.id"; }
    if( $group eq 'salemods')     { $group_string = " sm.id"; }
    if( $limit )                  { $limit_string = "LIMIT ".$limit; }
    if(!$type)                    { return undef;}else{ $btype= "bp.idType = $type ";}

    if( $order ){ $order = "ORDER BY ".$order; }else{ $order = "ORDER BY bp.sort"; }
    my @buf;
    my $sql = "SELECT sm.id
         FROM category c INNER JOIN salemods sm ON c.id = sm.idCategory 
       INNER JOIN brands b ON b.id = sm.idBrand 
       INNER JOIN bannerProducts bp ON bp.idMod = sm.id
            WHERE sm.price > 0 and bp.isPublic and not bp.deleted and sm.isPublic 
            and ".$btype."
                ".$category_string."
                ".$brand_string."
               GROUP BY ".$group_string."  
               ".$order." 
        ".$limit_string;
    my $sth = $db->prepare("$sql");
    $sth->execute();
    while (my $id = $sth->fetchrow_array){
        push @buf, Model::SaleMod->load($id),
    }
    return \@buf;
}

sub category_product_banners(){
    my $self = shift;
    my $idc = shift;
    my @buf;
    my $sth = $db->prepare("select bpt.id,bpt.title,count(*) as cnt from bannerProductTypes bpt inner join bannerProducts bp on bpt.id = bp.idType inner join salemods s on bp.idMod = s.id inner join category c on c.id = s.idCategory and c.id = ? group by bp.idType");
    $sth->execute($idc);
    while (my $item = $sth->fetchrow_hashref){
        push @buf,$item;
    }
    return \@buf;
}

sub check_products_public(){
#    my $sth = $db->prepare("update bannerProducts set isPublic = 0 where date_to < CURDATE()");
#    $sth->execute();
#    $sth = $db->prepare("update bannerProducts bp inner join salemods s on s.id=bp.idMod set bp.isPublic = 0 where s.isPublic = 0 or s.price = 0");
#    $sth->execute();
    return 1;
}

sub apr_type(){
    my $self = shift;
    my $idType    = shift;
    return 'undef' unless $idType;
    return Model::APRTypes->load($idType);
}

sub apr_section(){
    my $self = shift;
    my $idSection = shift;
    return 'undef' unless $idSection;
    return Model::APRSections->load($idSection);
}


1;
