package Model::Category;

use warnings;
use strict;

use Model;
use Model::Brand;
use Core::DB;
use Data::Dumper;
use Core::User;

our @ISA = qw/Model/;

sub db_table() {'category'};
sub db_columns() { qw/id name alias idParent categoryOrder isPublic deleted show_links product_list_cols compared showBanner show_mods short_desc_on_product/};
sub has_many() 	 {qw/salemods/};
sub db_indexes() {qw/id name alias sort/};

sub publicBrandInCat(){
    my $self = shift;

    unless($self->{_brands}){
        my $sth = $db->prepare('SELECT DISTINCT idBrand FROM salemods WHERE idCategory = ? AND isPublic ORDER BY idBrand');
        $sth->execute($self->{id});
        my @buffer;
        while (my ($brand) = $sth->fetchrow_array){
            push @buffer,Model::Brand->load($brand);
        }
        $self->{_brands} = \@buffer;
    }

    return $self->{_brands};
}

sub features_for_select(){ ###### need to delete after content features done
    my $self = shift;
    my @buffer;

    my $sth = $db->prepare("select fg.id fgid,
				   f.id fid,
				   fg.name fgname,
				   f.value fvalue
			      from feature_groups fg
			INNER JOIN features f ON fg.id = f.idFeatureGroup
			     where fg.idCategory = ?
			       and fg.searchable = 1
			       and fg.idParent != 0
			  GROUP BY concat(fgid,'_',fvalue)
			  ORDER BY fg.name, f.value;");

    $sth->execute($self->{id});
    while (my $item = $sth->fetchrow_hashref){
	    push @buffer,$item;
    }
    return \@buffer;
}


sub features_for_man_select(){ ###### need to delete after content features done
    my $self = shift;
    my @buffer;

    my $sth = $db->prepare("select fg.id fgid,
				   f.id fid,
				   fg.name fgname,
				   f.value fvalue,
				   fg.type type
			      from feature_groups fg
			INNER JOIN features f ON fg.id = f.idFeatureGroup
			     where fg.idCategory = ?
			       and fg.idParent != 0
			  GROUP BY fg.id
			  ORDER BY fg.name, f.value;");

    $sth->execute($self->{id});
    while (my $item = $sth->fetchrow_hashref){
	    push @buffer,$item;
    }
    return \@buffer;
}

sub image(){
    my $self = shift;
    unless ($self->{_image}){
	use Core::Gallery;
	$self->{_image} = Core::Gallery::Image::Default->new();
    }

    $self->{_image};
}


sub gallery(){
    my $self = shift;
    unless ($self->{_gallery}){
	use Core::Gallery;
	#load sale gallery
	use Cfg;
	my $name  = 'category/'.$self->{alias};
	my $gpath = $cfg->{'PATH'}->{'gallery'}.''.$name;
	my $dir_exist = opendir(DIR,$gpath) or `mkdir -m777 -p $gpath`;
	$self->{_gallery} = Core::Gallery->new($name);
    }
    return $self->{_gallery};
}



sub lookSubCategory(){
    my ($self,$alias) = @_;

    unless ($self->{_looksubcategory}){

		my $sth = $db->prepare('SELECT id FROM category WHERE idParent = ? AND alias = ?');
		$sth->execute( $self->{id}, $alias);
		my ($id) = $sth->fetchrow_array;

		$self->{_looksubcategory} = Model::Category->load($id);

    }

    return $self->{_looksubcategory};
}
sub list(){
    my ($class,$parent,$public) = @_;
    my $and = '';

    if ($public ne ''){
    	$and .= " AND $public = 1 ";
    }
    if ($parent ne ''){
    	$and .= " AND  idParent =  $parent";
    }

    my $sth = $db->prepare("SELECT id FROM category WHERE 1 $and ORDER BY idParent");
    $sth->execute();

    my @buffer;

    while(my ($id) = $sth->fetchrow_array){
		push @buffer,Model::Category->load($id);
    }

    return \@buffer;
}

sub childs(){
    my $self = shift;
    unless ($self->{_childs}){
	my $sth = $db->prepare('SELECT id FROM category WHERE idParent = ? ORDER BY categoryOrder,name');
	$sth->execute($self->{id}) or return $self->Error('Can`t load category childs');
	my @buffer = ();
	while (my ($id) = $sth->fetchrow_array){
	    push @buffer,Model::Category->load($id);
	}
	$self->{_childs} = \@buffer if @buffer;
    }
    return @{$self->{_childs}} if $self->{_childs};
    return undef;
}

sub childs_front(){
    my $self = shift;

    unless ($self->{_childs_front}){

		my $sth = $db->prepare('SELECT id FROM category WHERE idParent = ? AND isPublic = 1 ORDER BY categoryOrder');
		$sth->execute($self->{id});

		my @buffer = ();

		while (my ($id) = $sth->fetchrow_array) {

	    	push @buffer,Model::Category->load($id);

		}

		$self->{_childs_front} = \@buffer if @buffer;
    }

    return @{ $self->{_childs_front} } if $self->{_childs_front};

    return undef;
}


sub salemods_all(){
    my $self = shift;
    my @buf;

    unless ($self->{_salemods_all}){

		use Model::SaleMod;

		my $sth = $db->prepare('SELECT * FROM salemods WHERE idCategory = ? ORDER BY name');
		$sth->execute($self->{id}) or return $self->Error('Can`t load category childs');
		while (my $item = $sth->fetchrow_hashref){
			push @buf, Model::SaleMod->load($item->{id});
		}
		$self->{_salemods_all} = \@buf;
    }

    return $self->{_salemods_all};
}

sub salemods_off(){
    my $self = shift;

	my $sth = $db->prepare('UPDATE salemods set isPublic = 0 where idCategory = ?');
	$sth->execute($self->{id});

	return 1;

}

sub childs_off(){
    my $self = shift;

	my $sth = $db->prepare('UPDATE category set isPublic = 0 where idParent = ?');
	$sth->execute($self->{id});

	return 1;

}


sub childs_front_light(){
    my $self = shift;
    my @buf;
    unless ($self->{_childs_front_light}){

		my $sth = $db->prepare('SELECT id, name, alias FROM category WHERE idParent = ? AND isPublic = 1 ORDER BY categoryOrder');
		$sth->execute($self->{id}) or return $self->Error('Can`t load category childs');

		while (my $item = $sth->fetchrow_hashref){
			push @buf, $item;
		}

		$self->{_childs_front_light} = \@buf;
    }
    return $self->{_childs_front_light};
}

sub mods_count_act(){
    my $self = shift;
    unless ($self->{_mods_count_act}){
	my $sth = $db->prepare('select count(id) from salemods where idCategory = ? and isPublic = 1;');
	$sth->execute($self->{id});
	$self->{_mods_count_act} = $sth->fetchrow_array;
    }
    return $self->{_mods_count_act};
}

sub get_url(){
    my $self = shift;
    unless ($self->{_get_url}){

	if($self->mods_count_all() > 0 && $self->{idParent} > 0 ){
	    $self->{_get_url} = $self->parent()->{alias}."/".$self->{alias}."html";
	} else {
	    $self->{_get_url} = "/".$self->{alias}."html";
	}
    }
    return $self->{_get_url};
}


sub mods_count_all(){
    my $self = shift;
    unless ($self->{_mods_count_all}){
	my $sth = $db->prepare('select count(id) from salemods where idCategory = ?;');
	$sth->execute($self->{id});
	$self->{_mods_count_all} = $sth->fetchrow_array;
    }
    return $self->{_mods_count_all};
}


sub mods_count_price(){
    my $self = shift;
    unless ($self->{_mods_count_price}){
	my $sth = $db->prepare('select count(id) from salemods where idCategory = ? and price > 0 and isPublic = 1;');
	$sth->execute($self->{id});
	$self->{_mods_count_price} = $sth->fetchrow_array;
    }
    return $self->{_mods_count_price};
}

sub brands_count(){
    my $self = shift;

    unless ($self->{_brands_count}){
		my $sth = $db->prepare("select count(distinct(s.idBrand)) from salemods s INNER JOIN category as c ON s.idCategory = c.id where c.id = ? and s.isPublic = 1");
		$sth->execute($self->{id});
		$self->{_brands_count} = $sth->fetchrow_array;
    }
    return $self->{_brands_count};
}



sub brand_cat_salemod(){
    my $self = shift;
    my $brand = shift;
    my $page = shift;
    my @buffer;
    my $limit = shift;

    $limit = 12 unless $limit;
    $page = 1 unless $page;

    my $limit1 = ($page -1)*$limit;
    my $sth = $db->prepare("select count(*) from salemods as sm  LEFT JOIN brands as b ON sm.idBrand = b.id LEFT JOIN category as c ON sm.idCategory=c.id where c.id = ? and b.alias = ? and sm.isPublic = 1 ");
    $sth->execute($self->{'id'},$brand);
    my $sales->{'count'} = $sth->fetchrow_array;
    $sales->{'limit'} = $limit;
    $sales->{'page'} = $page;
    $sales->{'pages'} = int($sales->{'count'}/$sales->{'limit'}) + 1;


    $sth = $db->prepare("select sm.* from salemods as sm  LEFT JOIN brands as b ON sm.idBrand = b.id LEFT JOIN category as c ON sm.idCategory=c.id where c.id = ? and b.alias = ?  and sm.isPublic = 1 order by sm.price desc limit ?,?");
    $sth->execute($self->{'id'},$brand,$limit1,$limit);
    while (my $item = $sth->fetchrow_hashref){
        bless $item,"Model::SaleMod";
        push @buffer,$item;
    }
    $sales->{'list'} = \@buffer;
    return $sales;
}

sub parent(){
    my $self = shift;

    unless ($self->{_parent}){
		$self->{_parent} = Model::Category->load($self->{idParent}) or return $self->Error('Model::Category (parent) not loaded');
    }

    return $self->{_parent};
}

#todo: remove , because not needted. May use model->parent
sub path(){
    my $self = shift;
    unless($self->{_path}){
        my $pdh = $db->prepare('  SELECT id,
        								 name,
        								 alias,
        								 idParent
								    FROM category
								   WHERE id = ?
	    						 	ORDER BY categoryOrder');

    	my @buffer;
	my $id = $self->{id};
	do{
	    $pdh->execute($id);
	    my $item = $pdh->fetchrow_hashref; #maybe use Model::Category ?
	    push @buffer,$item;
	    $id = $item->{idParent};
    } while $id != 0;
	$pdh->finish;
	@buffer = reverse @buffer;
	$self->{_path} = \@buffer;

    }
    return $self->{_path};
}


sub strpath(){
    my $self = shift;
    my $delim = shift || ',';
    my @buf;

    foreach my $item (@{$self->path}){
		push @buf, $item->{name};
    }

    return join ($delim,@buf);
}

sub brandInCat(){
    my $self = shift;

    unless($self->{_brands}){

        my $sth = $db->prepare('SELECT DISTINCT idBrand FROM salemods WHERE idCategory = ? ORDER BY idBrand');
        $sth->execute($self->{id});

        my @buffer;

        while (my ($brand) = $sth->fetchrow_array){
            push @buffer,Model::Brand->load($brand);
        }

        $self->{_brands} = \@buffer;
    }

    return $self->{_brands};
}


sub brands(){
    my $self = shift;

    unless($self->{_brands}){

		my $sth ="SELECT b.name as name,
			 b.id as id,
			 b.alias as alias,
			 count(distinct(sm.id)) as bcount
				      FROM salemods as sm
			     STRAIGHT_JOIN brands as b ON b.id = sm.idBrand
				     WHERE sm.idCategory = ?
				       AND sm.isPublic = 1
				       AND sm.price > 0
			             GROUP BY b.name";
		my @buffer;
		$sth = $db->prepare($sth);
		$sth->execute($self->{id});

		while (my $xitem = $sth->fetchrow_hashref){
	    	push @buffer,{ item => $xitem };
		}
		$self->{_brands} = \@buffer;
    }
    return $self->{_brands};
}


sub brands_back(){
    my $self = shift;

    unless($self->{_brands}){
	my $sth ="SELECT b.name as name,
			 b.id as id,
			 b.alias as alias,
			 count(distinct(sm.id)) as bcount
				      FROM salemods as sm
			     STRAIGHT_JOIN brands as b ON b.id = sm.idBrand
				     WHERE sm.idCategory = ?
				       AND sm.isPublic = 1
			             GROUP BY b.name";
	my @buffer;
	$sth = $db->prepare($sth);
	$sth->execute($self->{id});

	while (my $xitem = $sth->fetchrow_hashref){
	    push @buffer,{ item => $xitem };
	}

	$self->{_brands} = \@buffer;
    }
    return $self->{_brands};
}


sub brand_min_salemod(){
    my ($self, $idBrand) = @_;
    my $sth ="select id as id,
		     min(price)
		FROM salemods WHERE
		     idCategory = ?
		 AND idBrand = ?
		 AND isPublic = 1
		 AND price > 0
		 AND price != 9999
	    GROUP BY price,name
	    ORDER BY price limit 1";
    $sth = $db->prepare($sth);
    $sth->execute($self->{id}, $idBrand);
    my $xitem = $sth->fetchrow_hashref;
    my $res = Model::SaleMod->load($xitem->{id});
    return $res;
}

sub brands_parent(){
    my $self = shift;
    unless($self->{_brands_parent}){
	my $sth ="SELECT b.name as bname,
			 b.alias as alias,
			 b.id as id,
			 c.id as cid,
			 c.alias as calias,
			 c.name as cname,
			 count(distinct(sm.id)) as bcount
		    FROM category c INNER JOIN salemods sm ON sm.idCategory = c.id
	       LEFT JOIN brands as b ON b.id = sm.idBrand
	           WHERE c.idParent = ?
                 AND b.id
	             AND sm.isPublic = 1
	        GROUP BY concat(b.id,',',c.id)
	        ORDER BY c.categoryOrder, c.id, b.name";
	my @buffer;
	$sth = $db->prepare($sth);
	$sth->execute($self->{id});
	while (my $xitem = $sth->fetchrow_hashref){
	    push @buffer, $xitem;
	}

	$self->{_brands_parent} = \@buffer;
    }
    return $self->{_brands_parent};
}


sub add_remote_img(){
    my ($self,$file) = @_;
    my $ngi;

    if($file){
	    use Core::Gallery;
	    use Image::Magick;
	    use LWP::UserAgent;
	    use Cfg;

	    my $fname = 'category/'.$self->{alias};
	    my $gpath = $cfg->{'PATH'}->{'gallery'}.$fname;

	    my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MyIE2; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',);
	    my $r = $ua->get($file);
	    my $cnt = $r->content();

	    my $dir_exist = opendir(DIR,$gpath) or `mkdir -p $gpath`;
	    closedir(DIR);

	    my ($name,$format) = ( $file  =~ /(\w+)\.(\w+)$/);
	    my $tow = $gpath."/f".$name.".".$format;

	    my $aaa = `wget --output-document=$tow $file &`;

	    my $img = Image::Magick->new();
	    my $x = open FIMG ,$tow;
	    $img->Read(file => \*FIMG);
	    close FIMG;
	    return undef unless $img->Get('width');

	    my $model = Core::Gallery::Image->new({
		name => $fname,
		width => $img->Get('width'),
		height => $img->Get('height'),
	    });
	    $model->save();

	    my $ysth = $db->prepare('SELECT max(id) FROM gallery');
	    $ysth->execute();
	    $ngi = $ysth->fetchrow_array;
	    $img->Write("$gpath/image_$ngi.png");
    }
    return $ngi;
}


sub models_list(){
    my ($self,$idBrand) = @_;
    my @buffer;
    my $sth = $db->prepare(" select sb.name as name, sb.id as id from salemods sm  INNER JOIN salemods sb ON sm.baseId = sb.id where sm.idCategory = ? and sm.idBrand = ? group by sb.id order by sb.name;");
    $sth->execute($self->{id}, $idBrand);

    while (my $xitem = $sth->fetchrow_hashref){
	push @buffer, $xitem;
    }

    return \@buffer;
}



sub price_limit(){
    my $self = shift;
    unless($self->{_price_limit}){

	my $sth ="SELECT round(min(price)) min_price, round(max(price)) max_price
				      FROM salemods as sm
				     WHERE idCategory = ?
				       AND isPublic = 1
				       AND price > 0
				       AND price != 9999";
	$sth = $db->prepare($sth);
	$sth->execute($self->{id});
	my $xitem = $sth->fetchrow_hashref;
	$self->{_price_limit} = $xitem;
    }
    return $self->{_price_limit};
}



sub top(){
    my $self = shift;

    unless ($self->{_top}){
	$self->{_top} = {
	    childs => Model::Category->list(0),
	};
    }

    return $self->{_top};

}

sub cat_salers(){
    my $self = shift;
    unless ($self->{_salers} ){
        my $sth = $db->prepare('SELECT id,name FROM salers WHERE FIND_IN_SET(?,categoryList)');
        $sth->execute($self->{id});
        use Model::Saler;
        while (my $item = $sth->fetchrow_hashref){
            push @{$self->{_salers}}, bless ($item,'Model::Saler');
        }
    }
    return $self->{_salers};
}

sub _check_write_permissions(){
    my $user = Core::User->current();
#    return 1 if $user->isInGroup('manager','root');

#    return undef;
return 1;
}

sub _check_columns_values(){
    my $self = shift;

    if($self->{alias})
    {
			return $self->einput('alias '.$self->{alias}.' is wrong')
	    	unless $self->{alias} =~ /^[A-Za-z0-9_-]+$/;
    }else{
			return $self->einput('alias not set');
    }
   			return 1;
}

sub _before_save(){
    my $self = shift;

    unless ($self->{id}){
	my $sth = $db->prepare("SELECT MAX(categoryOrder)+1 FROM category WHERE idParent = ?");
	$sth->execute($self->{idParent} || 0);
	($self->{categoryOrder}) = $sth->fetchrow_array;
    }
}

sub _before_delete(){
    my $self = shift;

}

sub changeorder(){
    my ($self,$position) = @_;

    my $sth = $db->prepare("SELECT id FROM category WHERE
			    (categoryOrder - ($position),idParent) IN
			    (SELECT c.categoryOrder,c.idParent FROM category c WHERE c.id = ?) LIMIT 1");

    $sth->execute($self->{id}) or return $self->Error('Can`t change order for category id='.$self->{id}.' pos='.$position.': '.$sth->errstr);

    my ($newid) = $sth->fetchrow_array;
    my $dth = $db->prepare("UPDATE category p1,category p2 SET
			p1.categoryOrder = p1.categoryOrder + ($position),
			p1.updated = NOW(),
			p2.categoryOrder = p2.categoryOrder - ($position),
			p2.updated = NOW()
			WHERE p1.id = ? AND p2.id = ?");
    $dth->execute($self->{id},$newid) or return $self->Error('Can`t set order for category id='.$self->{id}.' pos='.$position.': '.$sth->errstr);

}
sub bar(){
    my $self = shift;
    my @buffer;
    my $brand_filter;
    my $tmp_count;
    my $dth = $db->prepare("select id from categoryPriceBar where idCat = ? order by pfrom;");
    $dth->execute($self->{id});
    while (my ($id) = $dth->fetchrow_array){
	push @buffer, Model::PriceBar->load($id);
    }
    return \@buffer;
}

sub dec(){
    my $self = shift;
    unless ($self->{_dec}){
	my $dth = $db->prepare("select * from categoryDec where idCat = ? limit 1;");
	$dth->execute($self->{id});
	$self->{_dec} = $dth->fetchrow_hashref;
    }
    return $self->{_dec};
}

sub meta(){
    my $self = shift;
    unless ($self->{_meta}){
	my $dth = $db->prepare("select * from categoryMeta where idCat = ? limit 1;");
	$dth->execute($self->{id});
	$self->{_meta} = $dth->fetchrow_hashref;
    }
    return $self->{_meta};
}

sub adec(){
    my $self = shift;
    unless ($self->{_adec}){
	my $dth = $db->prepare("select * from categoryAltDec where idCat = ? limit 1;");
	$dth->execute($self->{id});
	$self->{_adec} = $dth->fetchrow_hashref;
    }
    return $self->{_adec};
}


sub categoryTopMenu(){
    my $self = shift;
    $self->{_CategoryTopMenu} ||= Model::CategoryTopMenu->load($self->{id},'idCat');
}


sub accessories(){
    my $self = shift;
    my @buffer;
    unless ($self->{_accessories}){
		my $dth = $db->prepare("select id, idACat from categoryAccessories where idCat = ?;");
		$dth->execute($self->{id});
		while (my ($id, $idACat ) = $dth->fetchrow_array){
	    	push @buffer, {
	    		cat      => Model::Category->load($idACat),
			 	acs      => Model::categoryAccessories->load($id)
			};
		}
		$self->{_accessories} = \@buffer;
    }
    return $self->{_accessories};
}


sub bar_copy(){
    my ($self,$idCat) = @_;
    my @buffer;
    my $dth = $db->prepare("delete from categoryPriceBar where idCat = ?;");
    $dth->execute($idCat);
    $dth = $db->prepare("select id from  categoryPriceBar where idCat = ? order by pfrom;");
    $dth->execute($self->{id});
    my $mod;
    my $mod2;
    while (my ($id) = $dth->fetchrow_array){
	$mod  = Model::PriceBar->load($id);
	$mod->{id}    = '';
	$mod->{idCat} = $idCat;
	$mod2 = Model::PriceBar->new($mod);
	$mod2->save();
    }
}

sub generate_filters(){
        my $self = shift;
        my $i = 1;

        $db->do("CREATE TEMPORARY TABLE filters_cache$$ ( `idFilter` int(11) NOT NULL, `idSalemod` int(11) NOT NULL, UNIQUE KEY `idFilter` (`idFilter`,`idSalemod`))");
        my $sth = $db->prepare("select f.*,g.type,g.idCategory from filters f inner join feature_groups g on f.idParent = g.id and g.idCategory = ?");
        $sth->execute($self->{id});

        while (my $item = $sth->fetchrow_hashref()) {

        my $idCategory = $item->{idCategory};
        warn " \n".$item->{rule}."   ".$item->{type}."   ".$item->{value}."  ".$item->{title}."  ".$item->{idCategory};

        if ($item->{rule} eq 'eq'  and ($item->{type} eq 'string' or $item->{type} eq 'int' or $item->{type} eq 'bool')) {
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where f.value = ? and g.idCategory = ? and g.id = ?");
                $isth->execute($item->{value},$idCategory,$item->{idParent});
        }

        elsif ($item->{rule} eq 'lk' and ($item->{type} eq 'string' or $item->{type} eq 'int'  or $item->{type} eq 'float')) {
                $item->{value} =~ s/\?/\_/;
                $item->{value} =~ s/\*/\%/;
                $item->{value} =~ s/\"//;
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where f.value like \"$item->{value}\" and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }

        elsif ($item->{rule} eq 'le' and $item->{type} eq 'int') {
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as SIGNED) < \"$item->{value}\" and f.value REGEXP '^-?[0-9]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        elsif ($item->{rule} eq 'me' and $item->{type} eq 'int') {
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as SIGNED) > \"$item->{value}\" and f.value REGEXP '^-?[0-9]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        elsif ($item->{rule} eq 'eq' and $item->{type} eq 'float') {
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as DECIMAL(7,2)) = cast(\"$item->{value}\" as DECIMAL(7,2)) and f.value REGEXP '^-?[0-9i,.]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        elsif ($item->{rule} eq 'le' and $item->{type} eq 'float') {
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as DECIMAL(7,2)) < \"$item->{value}\" and f.value REGEXP '^-?[0-9,.]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        elsif ($item->{rule} eq 'me' and $item->{type} eq 'float') {
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as DECIMAL(7,2)) > \"$item->{value}\" and f.value REGEXP '^-?[0-9,.]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        elsif ($item->{rule} eq 'be' and $item->{type} eq 'int') {
		my ($ot,$do) = split '\|',$item->{value};
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as SIGNED) BETWEEN \"$ot\" AND \"$do\" and f.value REGEXP '^-?[0-9,.]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        elsif ($item->{rule} eq 'be' and $item->{type} eq 'float') {
		my ($ot,$do) = split '\|',$item->{value};
                my $isth = $db->prepare("insert into filters_cache$$(idSalemod,idFilter) select distinct(f.idSaleMod), $item->{id} from features f inner join feature_groups g on f.idFeatureGroup = g.id where cast(f.value as DECIMAL(7,2)) BETWEEN \"$ot\" AND \"$do\" and f.value REGEXP '^-?[0-9,.]+\$' and g.idCategory = ? and g.id = ?");
                $isth->execute($idCategory,$item->{idParent});
        }
        $i++;
        }

        $db->do("delete f from filters_cache f left join filters_cache$$ tmp on f.idFilter = tmp.idFilter and f.idSalemod = tmp.idSalemod where tmp.idFilter is not null;");
        $db->do("insert into filters_cache select tmp.* from filters_cache$$ tmp left join  filters_cache f on f.idFilter = tmp.idFilter and f.idSalemod = tmp.idSalemod where f.idFilter is null");
}

package Model::PriceBar;
use Model;
use Core::DB;
use warnings;

our @ISA = qw/Model/;

sub db_table() {'categoryPriceBar'};
sub db_columns() {qw/id idCat pfrom pto deleted/};
sub db_indexes() {qw/id idCat/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub salemods_count(){
    my $self = shift;
    my $string;
    my $brand_filter;
    unless($self->{_salemods_count}){

		my $user = Core::User->current();
		if($user->session->get('filter_sales')){

    	    if($user->session->get('filter_sales')->{brands}){
	       		foreach my $brand_value (@{$user->session->get('filter_sales')->{brands}}){
	            	if($brand_value){
		            	$brand_filter = 'AND idBrand = '.$brand_value;
	            	}
	        	}
    	    }

	}
	if($self->{pfrom} != 0 || $self->{pto} != 0){
	    if($self->{pfrom} == 0 && $self->{pto} > 0){
		$string = 'AND price  <= '.$self->{pto};
	    }
	    if($self->{pfrom} > 0 && $self->{pto} > 0){
		$string = 'AND price BETWEEN '.$self->{pfrom}.' AND '.$self->{pto};
	    }
	    if($self->{pfrom} > 0 && $self->{pto} == 0){
		$string = 'AND price  >= '.$self->{pfrom};
	    }
	    my $dth = $db->prepare("select count(distinct(id)) as salemods_count from salemods where  idCategory = ? ".$brand_filter." AND price > 0 AND isPublic = 1 AND deleted != 1 $string;");
	    $dth->execute($self->{idCat});
	    $self->{_salemods_count} = $dth->fetchrow_hashref;
	    return $self->{_salemods_count};
	}
    }
}

package Model::CMeta;
use Model;

our @ISA = qw/Model/;

sub db_table() {'categoryMeta'};

sub db_columns() {qw/id idCat title metaKeywords metaDescription active deleted/};
sub db_indexes() {qw/id idCat/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

package Model::CDec;
use Model;

our @ISA = qw/Model/;

sub db_table()   { 'categoryDec' };
sub db_columns() { qw/id idCat one many kogoOne kogoMany komuOne komuMany chtoOne chtoMany kemOne kemMany naOne naMany gdeOne gdeMany/ };
sub db_indexes() { qw/id idCat/ };

sub _check_columns_values(){1};
sub _check_write_permissions(){1};
1;


package Model::CategoryAltDec;
use Model;

our @ISA = qw/Model/;

sub db_table() {'categoryAltDec'};
sub db_columns() {qw/id idCat one many kogoOne kogoMany naOne naMany kemOne kemMany descr descr_url deleted/};
sub db_indexes() {qw/id idCat/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};



package Model::categoryAccessories;
use Model;

our @ISA = qw/Model/;

sub db_table() {'categoryAccessories'};
sub db_columns() {qw/id idCat idACat deleted brand/};
sub db_indexes() {qw/id idCat idACat brand/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub category(){
    my $self = shift;
    unless ($self->{_category_acs}){
	$self->{_category_acs} = Model::Category->load($self->{id});
    }
    return $self->{_category_acs};
}

package Model::categoryMeta;
use Model;

our @ISA = qw/Model/;

sub db_table() {'categoryAccessories'};
sub db_columns() {qw/id idCat idACat deleted brand/};
sub db_indexes() {qw/id idCat idACat brand/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


package Model::CategoryTopMenu;
use Model;

our @ISA = qw/Model/;

sub db_table() {'categoryTopMenu'};
sub db_columns() {qw/id idCat col col2/};
sub db_indexes() {qw/id idCat col col2/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


1;
