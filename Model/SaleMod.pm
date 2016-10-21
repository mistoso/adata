package Model::SaleMod;

use latest;

use Core;           use DB; 
use Core::Gallery;  use Cfg;
use Model::Comment; use Data::Dumper;

our @ISA = qw/Model/;

sub db_table() {'salemods'};
sub db_columns { qw/ id idCategory idImage name alias Description DescriptionFull price rating discount odiscount garanty isPublic GalleryName coment idBrand  deleted priceAutogen baseId mark mpn/};

sub _check_columns_values(){1}
sub _check_write_permissions(){1}

our $LIST_INFO = { };

sub listChild(){
    my $self = shift;

    if ($self->isBase()) {
        unless ($self->{_base_list}){
            my @res;
            my $sth = $db->prepare('select id from salemods where baseId = ?');
            $sth->execute($self->{id});

            while (my $row = $sth->fetchrow_hashref){
                   push @res, Model::SaleMod->load($row->{id});
            }
	    $self->{_base_list} = \@res;
        }

        return $self->{_base_list};
    }
}

sub listChildPublic(){
    my $self = shift;

    if ($self->isBase()) {
        unless ($self->{_base_public_list}){
            my @res;
            my $sth = $db->prepare("select id from salemods where isPublic = '1' and baseId = ? and price > 0");
            $sth->execute($self->{id});
            while (my $row = $sth->fetchrow_hashref){
                   push @res, Model::SaleMod->load($row->{id});
            }
        $self->{_base_public_list} = \@res;
        }
        return $self->{_base_public_list};
    }
}

sub listModsPublic(){
    my $self = shift;

    if ($self->isChild()) {
        unless ($self->{_mods_public_list}){
            my @res;
            my $sth = $db->prepare("select id from salemods where baseId = ? and id != ? and baseId > 1 and isPublic = '1' and price > 0 ");
            $sth->execute($self->{baseId},$self->{id});
            while (my $row = $sth->fetchrow_hashref){
                   push @res, Model::SaleMod->load($row->{id});
        }
        $self->{_mods_public_list} = \@res;
        }
        return $self->{_mods_public_list};
    }
}

sub get_next_salemods(){
    my $self = shift;
    my $size           = shift || $cfg->{'temp'}->{'next_products_limit'};
    my $mods_count_act = $self->category->mods_count_act;
    if( $size > $mods_count_act ){$size = $mods_count_act;}

    my @buf;

    my $sth = $db->prepare("select * from salemods where id > ? and idCategory = ? and idBrand = ? and isPublic = 1 order by idBrand,id limit $size");

    $sth->execute($self->{id}, $self->{idCategory}, $self->{idBrand});

    while (my $item = $sth->fetchrow_hashref){
        $size--;
        push @buf, Model::SaleMod->load($item->{id});
    }

    if($size > 0 ){
        my $sth = $db->prepare("select * from salemods where id < ? and idCategory = ? and idBrand = ? and isPublic = 1 order by idBrand,id limit $size");
        $sth->execute($self->{id}, $self->{idCategory}, $self->{idBrand});
        while (my $item = $sth->fetchrow_hashref){
            $size--;
            push @buf, Model::SaleMod->load($item->{id});
        }
    }

    if($size > 0){
        my $sth = $db->prepare("select * from salemods where id < ? and idCategory = ? and isPublic = 1 and idBrand != ? order by idBrand,id limit $size");
        $sth->execute($self->{id}, $self->{idCategory}, $self->{idBrand});
        while (my $item = $sth->fetchrow_hashref){
            $size--;
            push @buf, Model::SaleMod->load($item->{id});
        }
    }

    if($size > 0){
        my $sth = $db->prepare("select * from salemods where id > ? and idCategory = ? and isPublic = 1 and idBrand != ? order by idBrand,id limit $size");
        $sth->execute($self->{id}, $self->{idCategory}, $self->{idBrand});
        while (my $item = $sth->fetchrow_hashref){
            $size--;
            push @buf, Model::SaleMod->load($item->{id});
        }
    }

    return \@buf;
}
sub video(){ 
    my $self = shift; 
    $self->{video} ||= Core->video('salemods',$self->{'id'}); 
}
sub listMods(){
    my $self = shift;

    if ($self->isChild()) {
        unless ($self->{_mods_list}){
            my @res;
            my $sth = $db->prepare('select id from salemods where baseId = ? and id != ? and baseId > 1');
            $sth->execute($self->{baseId},$self->{id});
            while (my $row = $sth->fetchrow_hashref){
                   push @res, Model::SaleMod->load($row->{id});
            }
        $self->{_mods_list} = \@res;
        }
        return $self->{_mods_list};
    }
}

sub get_base(){
    my $self = shift;
    if ($self->isChild()) {
        $self->{_base} ||= Model::SaleMod->load($self->{baseId});
    }
}

sub exlist(){
    my $args = shift;
    return undef unless $args->{dummy};

    my $result = ModelList->new('Model::SaleMod',$args->{page},50);

    $result->like( name => '%'.$args->{name}.'%') if $args->{name}; 
    $result->filter ( id => $args->{id}) if $args->{id};
    $result->skip_external_filter(1);

    if ($args->{idBrand}){
        $result->filter( 'salemods.idBrand' => $args->{idBrand});
    }
    if ($args->{idCategory}){
        $result->filter( 'salemods.idCategory' => $args->{idCategory});
    }
    $result->load();
    return $result;
}
sub category(){
    my $self = shift;
    use Model::Category;
    $self->{_category} ||= Model::Category->load($self->{idCategory});
}


sub brands(){ my $self = shift; $self->{_brands} ||= Model::Brand->load($self->{idBrand}); }

sub Description(){ my $self = shift; return $self->{Description}; }

sub bDescription(){
    my $self = shift;
    return $self->{Description};
}
sub DescriptionFull(){
    my $self = shift;
    return $self->{DescriptionFull};
}
sub bDescriptionFull(){
    my $self = shift;
    return $self->{DescriptionFull};
}
sub bprice(){
    my $self = shift;
    $self->{_price} ||= Core::PriceTool->new($self->{price});
}

sub price(){
    my $self = shift;
    return $self->bprice->price(shift);
}

sub image(){
    my $self = shift;
    $self->{_image} ||= Core::Gallery::Image::Default->new();
}





sub gallery_catalog(){
    my $self = shift;

    unless ($self->{_gallery_catalog}){

    #############ivan test####################

    if(!$self->{GalleryName}){

        my $p = $self->{alias};	
        $self->{GalleryName} = $p;
        $self->save();

        our $gpath = $cfg->{'PATH'}->{'gallery'}.$p;	
        `mkdir -m777 -p $gpath` unless( -d $gpath );
        $self->{_gallery_catalog} = Core::Gallery->new($p);
    }
    else{
        $self->{_gallery_catalog} = Core::Gallery->new($self->{GalleryName});
    }
    
    }
    return $self->{_gallery_catalog};
}

sub gallery(){
    my $self = shift;

    unless ( $self->{_gallery} ){

        my $p = $self->{alias};

        unless ( $self->{GalleryName} =~ /\w+/ ) {
	    	return 0 unless $p;
            $self->{GalleryName} = $p;
            $self->save();
        }

        our $gpath = $cfg->{'PATH'}->{'gallery'}.$p;

		return 0 unless $gpath;
		`mkdir -m777 -p $gpath` unless( -d $gpath );
		$self->{_gallery} = Core::Gallery->new($p);

    }
    
    return $self->{_gallery};
}

sub add_remote_img_check_src() {
  my ($self, $file) = @_;  

  use Model::GallerySrc;
  my $mod = Model::GallerySrc->load( $file, 'src' );  

  unless($mod) {

	my $id = $self->add_remote_img($file); 

	if($id) { 
	  my $sth = $db->prepare("insert into gallery_src set idGallery = ?, src = ?;"); 
	  $sth->execute($id, $file); 
	}

  }
}

sub img(){
    my $self = shift; #$self->{_image} ||= Core::Gallery::Image->load($self->{idImage}) || $self->basemodel->gallery->top();
}

sub feel_saler_prices(){
    my ($self,$args) = @_;
    return unless $self->allsalers;

    foreach my $saler (@{$self->allsalers}){
        next if (($args->{"sp$saler->{id}"} eq  $args->{"spo$saler->{id}"}) || $args->{"sp$saler->{id}"} eq '');
        
        my $price = $args->{"sp$saler->{id}"} || 0;
        my $uniq = $args->{"sq$saler->{id}"} || 0;
        my $vip = $args->{"vip$saler->{id}"} || 0;
        my $stockComment = $args->{"si$saler->{id}"} || '';
        
        my $sth = $db->prepare('REPLACE salerprices SET idSaleMod = ?, idSaler = ?, price = ?, uniqCode = ?, stockComment = ?,vip = ?');
        
        $sth->execute($self->{id},$saler->{id},$price,$uniq,$stockComment,$vip) or warn "Error here:".$sth->errstr;
        warn "Have to set: id = $self->{id}, saler = $saler->{id}, price = $price, uniq = $uniq";

    }
    return 1;

}


sub add_remote_img(){
    my ($self, $file) = @_;

    my $id = $self->gallery->addRemote($file);

    return $id;
}

sub import_remote_img(){
    my ($self, $file) = @_;

    my $id = $self->gallery->addRemote($file);

    if($id){
        my $sth = $db->prepare("update salemods set idImage = ? where id = ?;");
        $sth->execute( $id, $self->{id});
    }

    return $id;
}


sub price_limit_mods(){
    my $self = shift;
    unless($self->{_price_limit_mods}){
    my $sth ="  SELECT  min(price) min_price, max(price) max_price
                FROM    salemods
                WHERE   baseId = ?
                    AND deleted != 1
                    AND isPublic = 1
                    AND price > 0
                    AND price != 9999;  ";
    my @buffer;
    $sth = $db->prepare($sth);
    $sth->execute($self->{id});
    my $xitem = $sth->fetchrow_hashref;

    $self->{_price_limit_mods} = $xitem;
    }
    return $self->{_price_limit_mods};
}

sub allsalers(){
       my $self = shift;
       unless ($self->{_salers} ){
               my $sth = $db->prepare('SELECT id FROM salers WHERE FIND_IN_SET(?,categoryList) AND deleted != 1');
               $sth->execute($self->category->{id});
               use Model::Saler;
               while (my ($id) = $sth->fetchrow_array){
                       push @{$self->{_salers}}, Model::Saler->load($id);
               }
       }
       return $self->{_salers};
}

sub arkhiv() {
       my ($self,$args) = @_;
       my $time = time();
       if (($args->{old_price} ne '')  && ($args->{old_price} ne $args->{price})){
               my $sth = $db->prepare('insert into price_arch (kod_tovar,last_update,mt_cena) value (?,?,?)');
               $sth->execute($args->{id},$time,$args->{price});
       }
       return 1;
}

sub show_arkhiv(){
       my ($self) = @_;
       my @res;
       my $sth = $db->prepare("SELECT DISTINCT(DATE_FORMAT(FROM_UNIXTIME(last_update),'%e-%m-%y')) as date, mt_cena as price FROM price_arch WHERE kod_tovar=".$self->{id}." AND last_update<>'' AND mt_cena<>'' GROUP BY date ORDER BY last_update DESC LIMIT 0,10 ");
       $sth->execute();
       while (my $row = $sth->fetchrow_hashref){
               push (@res, $row);
       }
       return \@res;
}

sub get_features {
    my $self = shift;

    my @buf = ();

    my $sth = $db->prepare("select id, name from feature_groups where idCategory = ? and name <> '' and idParent = 0 order by orderby");
    $sth->execute($self->{idCategory});

    my @features = ();
    while (my $feature_group = $sth->fetchrow_hashref()) {

        my @tmp = ();
        my $csth = $db->prepare("select f.id as id, g.name as name, f.value as value, g.measure as measure, g.type as type
                                    from features f 
                                    inner join feature_groups g 
                                        on f.idFeatureGroup = g.id 
                                    where g.public and not g.deleted and g.idParent  = ? and f.idSaleMod = ? and f.value <> '' 
                                order by g.orderby");
        $csth->execute($feature_group->{id},$self->{id});

        while(my $item = $csth->fetchrow_hashref()) {
            push (@tmp,$item);
        }   

        if (scalar(@tmp) > 0) {
            $feature_group->{childs} = \@tmp;
            push (@features,$feature_group);
        }
    }
    return \@features;
}

sub price_limit_brand(){
    my $self = shift;
    unless($self->{_price_limit_brand}){
    my $sth ="SELECT min(price) min_price, max(price) max_price    
                      FROM salemods as sm  
                     WHERE idCategory = ?
                       AND idBrand = ?
                       AND deleted != 1
                       AND isPublic = 1
                       AND price > 0
                       AND price != 9999"; 
    my @buffer;
    $sth = $db->prepare($sth);    
    $sth->execute($self->{idCategory}, $self->{idBrand});
    my $xitem = $sth->fetchrow_hashref;
    push @buffer,($xitem->{min_price},$xitem->{max_price}); 
    
    
    $self->{_price_limit_brand} = \@buffer;
    }
    return $self->{_price_limit_brand};
}

sub __salers_names {
    my $self = shift;

    my $sth = $db->prepare("select id, name from salers");
    $sth->execute();

    while (my ($id,$name) = $sth->fetchrow_array()) {
        $self->{__salers_names}->{$id} = $name;
    }
}

sub minsaler(){
    my $self = shift;

    unless ($self->{__salers_names}) {
        $self->__salers_names();
    }
    my $sth = $db->prepare("
        SELECT  price,idSaler,DATE_FORMAT(updated,'%d.%m.%y') 
        FROM salerminprice 
        WHERE idSaleMod = ?
        ");
    $sth->execute($self->{id});

    my @buf;
    my ($price,$idSaler,$updated) = $sth->fetchrow_array();   
    return {
            'price' => $price, 
            'name'  => $self->{__salers_names}->{$idSaler},
            'id'    => $idSaler,
            'updated'=> $updated,
           };
}

sub priceautogen(){
    my $self = shift;
    my $idSaler;
    my $updated;
    my $minprice;
    my $PublicStatus = 0;
    my $salemodprice = 0;
    my $percentage = 0;
        my $th_minprice_vip = $db->prepare("SELECT idSaler,updated,price FROM salerprices WHERE price = (SELECT min(price) FROM salerprices WHERE price > 0 AND idSaleMod = ? and vip GROUP BY idSaleMod) AND idSaleMod = ? and vip");
        $th_minprice_vip->execute($self->{id},$self->{id});
        ($idSaler,$updated,$minprice) =$th_minprice_vip->fetchrow_array();
        unless ($minprice){
            my $th_minprice = $db->prepare("SELECT idSaler,updated,price FROM salerprices WHERE price = (SELECT min(price) FROM salerprices WHERE price > 0 AND idSaleMod = ? and not vip GROUP BY idSaleMod) AND idSaleMod = ? and not vip");
            $th_minprice->execute($self->{id},$self->{id});
            ($idSaler,$updated,$minprice) =$th_minprice->fetchrow_array();
            unless ($minprice){ $minprice = '0'; }
        }
        my $sth = $db->prepare('REPLACE salerminprice SET idSaleMod = ?, idSaler = ?, price = ?, updated = ?');
        $sth->execute($self->{id},$idSaler,$minprice,$updated);

    if ($self->{priceAutogen} eq '1'){
        if ($minprice > 0){
            my $ssth = $db->prepare("select salers_id,IFNULL(value,0),percentage from subprices where cat_id = ? and brand_id = ? and max_price >= ? and min_price <= ? and salers_id is not null ");
            $ssth->execute($self->{idCategory},$self->{idBrand},$minprice,$minprice);
            my ($ids,$marge,$percentage) = $ssth->fetchrow_array();
            my $item;
            if ($marge > 0){
                    my $msth = $db->prepare("select idSaler,updated,price FROM salerprices WHERE price = (SELECT min(price) FROM salerprices WHERE price > 0 AND idSaleMod = ? and idSaler in ($ids) GROUP BY idSaleMod) AND idSaleMod = ? and idSaler in ($ids)");
                    $msth->execute($self->{id},$self->{id});
                    $item = $msth->fetchrow_hashref();
            }
            if (!($item->{price} ) && !($marge)){
                my $psth = $db->prepare("select IFNULL(value,0),percentage from subprices where cat_id = ? and brand_id = ? and max_price >= ? and min_price <= ? and salers_id is null");
                $psth->execute($self->{idCategory},$self->{idBrand},$minprice,$minprice);
                ($marge,$percentage) = $psth->fetchrow_array();
                if ($percentage eq '1' and $marge ){
                    $salemodprice = $minprice + ($minprice*($marge/100));
                }elsif($percentage eq '0' and $marge ){
                    $salemodprice = $minprice + $marge;
                }
                unless ($salemodprice){
                    my $pth = $db->prepare("select IFNULL(value,0),percentage from subprices where cat_id = ? and brand_id = '0' and max_price >= ? and min_price <= ? and salers_id is null");
                    $pth->execute($self->{idCategory},$minprice,$minprice);
                    ($marge,$percentage)= $pth->fetchrow_array();
                    if ($percentage eq '1' and $marge ){
                        $salemodprice = $minprice + ($minprice*($marge/100));
                    }elsif($percentage eq '0' and $marge ){
                        $salemodprice = $minprice + $marge;
                    }
                    if (($salemodprice eq '') || ($salemodprice eq 0) || !($salemodprice) ){
                        $salemodprice = 0 + $minprice;
                    }
                }
            }elsif(!($item->{price}) && ($marge)){
                $salemodprice = $marge + $minprice;
            }else{
                my $sth = $db->prepare('REPLACE salerminprice SET idSaleMod = ?, idSaler = ?, price = ?, updated = ?');
                $sth->execute($self->{id},$item->{idSaler},$item->{price},$item->{updated});
                $salemodprice = $item->{price} + $marge;
            }
            $PublicStatus = 1;
        }else{
            $salemodprice = 0;
        }
        $self->{'price'} = sprintf('%.'.$cfg->{'temp'}->{'price_coin'}.'f',$salemodprice);
        $self->{'isPublic'} = $PublicStatus;
        $self->save();
    }
    return 1;
}

sub comments(){
    my $self = shift;
    
    $self->{comments} = Model::Comment->comments_for_mod($self->{'id'},'ok');
    
    return $self->{comments};
}


sub get_features_value() {
    my $self = shift;
    my $fid = shift;

    my $sth = $db->prepare("select value from features where idSalemod = ? and idFeatureGroup = ?");
    $sth->execute($self->{id},$fid);
    my $value = $sth->fetchrow_array();
    
    return $value;
}

sub has_features(){
    my $self = shift;
    my $sth = $db->prepare("select count(*) from features where idSalemod = ? ");
    $sth->execute($self->{id});
    my $value = $sth->fetchrow_array();
    return 1 if $value > 1;
    return 0;
}

sub get_features_desc() {
    my $self = shift;
    unless ($self->{_features_desc} ){
    my $sth = $db->prepare("select fg.name name, 
             fl.title title 
            from feature_groups fg 
          INNER JOIN filters fl ON fg.id = fl.idParent 
          INNER JOIN filters_cache flc ON flc.idFilter = fl.id 
               WHERE flc.idSalemod = ?
                 AND fg.searchable = 1");
    $sth->execute($self->{id});
    my $xitem = $sth->fetchrow_hashref;
    $self->{_features_desc}  = $sth->fetchrow_hashref;
    }
    return $self->{_features_desc};
}

sub catalogPrices(){
    my $self = shift;
    my $idcatalog = shift;
    my @buf;
    my $catalog = '';
    $catalog = " and idCatalog = $idcatalog " if $idcatalog ne '';

    my $sth = $db->prepare("select c.* from catalog as c inner join catalogPrices as cp on c.id = cp.idCatalog where cp.idMod = ? $catalog group by cp.idCatalog");
    $sth->execute($self->{'id'});

    while (my $catalog = $sth->fetchrow_hashref){
        my $sth = $db->prepare("select * from catalogPrices where idMod = ? and idCatalog = ? order by uprice");
        $sth->execute($self->{'id'},$catalog->{'id'});
        while (my $item = $sth->fetchrow_hashref){
            push @{$catalog->{'prices'}},$item;
        }
        push @buf,$catalog;
    }
    return \@buf;
}

sub rightMarks(){
    my $self = shift;
    my @buf;
    warn $self->{'idCategory'};
    my $sth = $db->prepare("select name,link,galleryname from categoryMarks where idCategory = ? order by sort");
    $sth->execute($self->{'idCategory'});
    while (my $mark = $sth->fetchrow_hashref){
        push @buf,$mark;
    }
    return \@buf;
    warn Dumper(@buf);
}

sub right_info(){
    my $self = shift;
    my $typeId = shift;
    my $sectionId = shift;
    my $limit = shift;
    my $buf = Core->apr_pages_banner_list($typeId,$self->{'idCategory'},$sectionId,$limit);
    my $sth = $db->prepare("select distinct(aprp.id) from apr_types aprt INNER JOIN apr_sections aprs ON aprt.id = aprs.type INNER JOIN apr_pages as aprp ON aprs.id = aprp.idCategory inner JOIN apr_contacts as aprc ON aprc.idPage = aprp.id inner join salemods as s on s.id = aprc.idMod WHERE aprt.id =?  AND aprs.id = ? AND s.id = ? AND aprc.deleted != 1 AND aprs.isPublic != 0  ORDER BY aprt.sort,aprs.sort ,aprs.name ,aprp.date_from DESC, aprp.name");
    $sth->execute($typeId,$sectionId,$self->{'id'});
    while (my $id = $sth->fetchrow_array){
        push @{$buf},Model::APRPages->load($id);
    }
    return $buf;
}

sub listConformProductsStylus(){
    my $self = shift;
    unless ( $self->{_list_conformity_products_stylus} ){
	$self->{_list_conformity_products_stylus}  = Search->new->search( 'db_sproducts', $self->{name} );
    }
    return $self->{_list_conformity_products_stylus};
}

sub import()  { my $id = shift; }

sub isBase()  { my $self = shift; return 1 if $self->{baseId} == 1; }

sub isChild() { my $self = shift; return 1 if $self->{baseId}  > 1; }

sub isStd()   { my $self = shift; return 1 if $self->{baseId} == 0; }

1;
