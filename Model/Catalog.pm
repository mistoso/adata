############################################################################
package Model::Catalog;
use Model;
use Core::DB;
use Data::Dumper;
use Cfg;
use Core::Gallery;

use Excel::Template;
use Core::Template qw/get_template/;


our @ISA = qw/Model/;
sub db_table() {'catalog'}
sub db_columns() {qw/id name file type info price currency bottomFrame isPublic deleted parse_func/};


sub _check_columns_values(){1};
sub _check_write_permissions(){1};


sub category_list(){
    my $self = shift;
    my @buffer;
    my $dth = $db->prepare("select cc.id, cc.idCatalog  
			      from catalogCategory cc INNER JOIN category c ON cc.idCat = c.id 
			     where cc.idCatalog = ? 
			       AND c.isPublic = 1 
			  order by c.idParent, c.name, cc.deleted;");
    $dth->execute($self->{id});
    while (my ($id, $idCatalog ) = $dth->fetchrow_array){
	push @buffer, { cat       => $self, 
			ccat      => Model::CatalogCategory->load($id)
		      };
		          
    }
    return \@buffer;
}

sub catalog_prod_count(){
	my $self = shift;
        my $sth = $db->prepare("select count(sm.id) as smcount
                  FROM catalog cl INNER JOIN catalogCategory cc ON cl.id = cc.idCatalog 
                INNER JOIN category c ON cc.idCat = c.id 
                INNER JOIN salemods sm ON c.id = sm.idCategory
                INNER JOIN brands b ON sm.idBrand = b.id 
                 WHERE sm.price > ".$self->{price}."
                   AND sm.isPublic = 1 
                   AND sm.deleted != 1 
                   AND cl.id = ? 
                   AND cl.deleted = 0 
                   AND cl.isPublic = 1");
	$sth->execute($self->{id});
	my ($smcount) = $sth->fetchrow_array;
	return $smcount;
}

sub catalog_post_all_cat(){
    	$self = shift;
	my $csth = $db->prepare("delete from catalogCategory where idCatalog = ? ");
	$csth->execute($self->{id});

    	my $sth = $db->prepare("select 	   distinct(sm.idCategory) as idCat
			      from salemods sm INNER JOIN category c ON sm.idCategory = c.id
			     where c.idParent != 0 

			       and c.deleted != 1 
			       and sm.deleted != 1 
			       and c.isPublic = 1 
			       and sm.isPublic = 1;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	my $csth = $db->prepare("select count(*) cc from catalogCategory where idCatalog = ? and idCat = ?;");
	$csth->execute($self->{id}, $item->{idCat});
	my ($cc) = $csth->fetchrow_array;
	if($cc<1 && $item->{idCat}){
	    $item->{id} = '';
	    $item->{idCatalog} = $self->{id};
	    $item->{isPublic} = 1;
	    $model = Model::CatalogCategory->new($item);
	    $model->save();	    
	}	 

    }

    return 1;
}

sub catalog_settings_list(){
    my $self = shift;
    my @buffer;
    my $sth = $db->prepare('select count(id) from catalogSettings where idCatalog = ? AND format = ?');
    $sth->execute($self->{id}, $self->{type});
    my $count = $sth->fetchrow_array;

    if($count < 1)
    {	
	my $sth = $db->prepare("select * from catalogSettingsDefault;");
	$sth->execute();

	while (my $item = $sth->fetchrow_hashref){
	    $item->{id} = '';
	    $item->{idCatalog} = $self->{id};
	    $item->{format} = $self->{type};
	    $model = Model::CatalogSettings->new($item);
	    $model->save();
	}
    }

    my $sth = $db->prepare("select * from catalogSettings where format = ? and idCatalog = ? order by sort, isPublic");
    $sth->execute($self->{type}, $self->{id});
    while (my $item = $sth->fetchrow_hashref){
	push @buffer, $item; 
    }
    return \@buffer;
}

sub catalog_drow_csv(){
    my $self = shift;

    my $temp_path = $cfg->{'PATH'}->{'templates'}.'backoffice/templates/catalog/cat_temp/'.$self->{id}.'_'.$self->{type}.'.html';

    my $line .= '<!-- FOR pos = rows -->';
    my $sth = $db->prepare("select * from catalogSettings where format = ? and idCatalog = ? and isPublic = 1 order by sort, isPublic");
    $sth->execute($self->{type}, $self->{id});

    while (my $item = $sth->fetchrow_hashref){
        $item->{sep} =~ s#\\t#\\\t#g;
        $item->{sep} =~ s#\\##g;
       $line .= '<!-- pos.' .$item->{fieldName}.' -->'.$item->{sep};
    }

    $line .= "\n";
    $line .= '<!-- END -->';
    open(FILE, ">".$temp_path) or die "dsfsdf";
    print(FILE "$line");
    close FILE;


}




sub catalog_drow_xls(){
    my $self = shift;
    my $temp_path = $cfg->{'PATH'}->{'templates'}.'backoffice/templates/catalog/cat_temp/'.$self->{id}.'_'.$self->{type}.'.xml';
    my $tmp_path  = $cfg->{'PATH'}->{'tmp'}.''.$self->{id}.'_'.$self->{type}.'.xml';
    my $put  = $cfg->{'stt_catalog'}->{'OUTPUT_PATH'}.''.$self->{file};

    my $line .= '[% FOR pos = rows %]
			    <row>';
	      
    my $rows .= '<?xml version="1.0" encoding="windows-1251" ?>
		    <workbook>
		    <worksheet  name="main-table">
			<format size="8" >
    			<format bold="1" >
			    <row>';
    my $sth = $db->prepare("select * from catalogSettings where format = ? and idCatalog = ? and isPublic = 1 order by sort, isPublic");
    $sth->execute($self->{type}, $self->{id});
    while (my $item = $sth->fetchrow_hashref){
	$rows .= '<cell text="'.$item->{fieldName}.'" width="9" />'; 
	$line .= '<cell text="[% pos.'.$item->{dbName}.' %]" />';
    }
    $rows .=		   '</row>
			</format>';
    $line .= '		</row>
		    [% END %]
		    </format>
		</worksheet>
		</workbook>';


    $rows .= $line;
    open(FILE, ">".$temp_path) or die $!;
    print(FILE "$rows");
    close FILE;


    my $file = $catalog->{file};
    my $tt = Template->new({ABSOLUTE => 1});
    $tt->process($temp_path, {rows => $self->catalog_xls_csv_data()} , $tmp_path) or die $tt->error();
    my $xls = Excel::Template->new(filename => $tmp_path);
    my $put = $cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."$self->{file}";
    open(FILE, ">".$put) or die $!;
    print(FILE $xls->output());
    close FILE;

    return OK;
}

sub catalog_get_xml_cat(){
	my $self = shift;
	warn "\n\n\n xls_csv_data() $self->{id} \n\n\n";
	use Model::SaleMod;
	use Model::Category;
	use Model::Brand;
	my @report_data;
	my $sth;
	my $currency_v = Model::Currency->load($self->{currency});
        $sth = $db->prepare("select c.id,
    				    c.name,
    				    ccc.id,
    				    ccc.name
                  FROM catalog cl 
                INNER JOIN catalogCategory cc ON cl.id = cc.idCatalog 
                INNER JOIN category c ON cc.idCat = c.id 
                INNER JOIN category ccc ON c.idParent = ccc.id
                INNER JOIN salemods sm ON c.id = sm.idCategory 

                 WHERE sm.price > ".$self->{price}."
                   AND cc.isPublic = 1
                   AND cc.deleted != 1
                   AND sm.isPublic = 1 
                   AND sm.deleted != 1 
                   AND cl.id = ? 
                   AND cl.deleted = 0 
                   AND cl.isPublic = 1
                   AND c.deleted != 1
                   AND c.isPublic = 1
                   
                  GROUP BY c.id 
                  ORDER BY c.idParent, c.name;");
	$sth->execute($self->{id});
	my $i;
	while (my ( $cat_id,$cat_name,$cat_parent_id,$cat_parent_name ) = $sth->fetchrow_array){
    	    $i++;
	    my $kod_rubriki     = $cat_parent_id; 
	    my $name_rubriki    = $cat_parent_name;
	    my $kod_podrubriki  = $cat_id; 
	    my $name_podrubriki = $cat_name; 

	    $name_rubriki =~ s/'//g;
	    $name_rubriki =~ s/\&//g;
	    $name_rubriki =~ s/\<//g;
	    $name_rubriki =~ s/\>//g;	
	    $name_rubriki =~ s/\n//g;	

	    $name_rubriki =~ s/"//g;
	    $name_rubriki =~ s/"//g;

	    $name_podrubriki =~ s/"//g;
	    $name_podrubriki =~ s/'//g;
	    $name_podrubriki =~ s/\&//g;
	    $name_podrubriki =~ s/\<//g;
	    $name_podrubriki =~ s/\>//g;	
	    $name_podrubriki =~ s/\n//g;	
	    my $item =  { kod_rubriki => $kod_rubriki, 			 
			  name_rubriki => $name_rubriki, 			 
			  kod_podrubriki => $kod_podrubriki, 
			  name_podrubriki => $name_podrubriki,
			  currency_v => $currency_v->{value},
			};
        	push @report_data, $item;
	}
	warn " \n\n $i -------- $self->{file} rubriki ------------- \n\n";
	return \@report_data;
}
sub catalog_get_xml_prod(){
	my $self = shift;
	use Model::SaleMod;
	use Model::Category;
	use Model::Brand;
	my $currency_v = Model::Currency->load($self->{currency});
	my $currency_ua = Model::Currency->load('1');

	my @report_data;
	my $sth = $db->prepare("select cl.id,cl.price,cc.idCat,cc.brands,cc.mods,cc.extprice FROM catalog cl INNER JOIN catalogCategory cc ON cl.id = cc.idCatalog where cc.isPublic = 1 AND cc.deleted != 1 AND cl.deleted = 0 AND cl.isPublic = 1 and cl.id = ?");
    $sth->execute($self->{id});
    while (my ($id, $price,$idc,$brands,$mods,$extprice) = $sth->fetchrow_array){

        my $q ="select c.id, sm.id, sm.name, sm.alias, sm.price, b.name, c.name, sm.GalleryName, sm.garanty, 1 as ext,'','' FROM category as c INNER JOIN salemods sm ON c.id = sm.idCategory INNER JOIN brands b ON sm.idBrand = b.id WHERE c.id = ? and sm.price > ? AND sm.isPublic = 1 AND sm.deleted != 1 AND c.deleted != 1 AND c.isPublic = 1";
        warn "$id, $price,$idc,$brands,$mods,$extprice";
        if ($mods ne '0'){ $q .= " and sm.id in ($mods) ";}
        elsif ($brands ne '0'){ $q .= " and sm.idBrand in ($brands) ";}
        else {}
        $q .=" ORDER BY c.name, sm.name";
        warn $q;
        my $sth = $db->prepare($q);
        $sth->execute($idc,$price);
	my $i;
	while (my ($cat_id, $prod_id,$prod_name,$prod_alias,$prod_price, $brand_name, $name_rubriki, $GalleryName, $garanty, $ext, $spupdated, $extprice) = $sth->fetchrow_array){
      if($ext > 0){   
	    my $salemod  = Model::SaleMod->load($prod_id);
	    my $name_brand      = $brand_name; 
	    my $kod_tovar 	= $prod_id; 
	    my $name_tovar	= $prod_name; 
	    my $url_tovar	= $cfg->{'stt_catalog'}->{'HOST'}.$prod_alias.".htm";
	    my $img_tovar	= '0';
	    my $img_tovar_prev	= '0';
	    my $desc_tovar	= 'desc'; 
	    my $garanty_tovar	= $garanty;
	    my $price		= $prod_price;
	    my $tovar_model = $salemod;
	    
        if ($salemod->{'idImage'} && $salemod->{'GalleryName'}){
            $img_tovar = $cfg->{'stt_catalog'}->{'HOST'}."gallery/".$salemod->{'GalleryName'}."/image_".$salemod->{'idImage'}.".png";
	    $img_tovar_prev = $cfg->{'stt_catalog'}->{'HOST'}."gallery/".$salemod->{'GalleryName'}."/image_".$salemod->{'idImage'}."_150_150.jpg";
	}
        $name_tovar =~ s/'//g;
	    $name_tovar =~ s/&//g;
	    $name_tovar =~ s/\<//g;
	    $name_tovar =~ s/\>//g;	
	    $name_tovar =~ s/\n//g;	
	    $name_tovar =~ s/"//g;
	    
        $desc_tovar =~ s/'//g;
	    $desc_tovar =~ s/&//g;
	    $desc_tovar =~ s/\<//g;
	    $desc_tovar =~ s/\>//g;	
	    $desc_tovar =~ s/\n//g;	
	    $desc_tovar =~ s/"//g;

	    
        $name_brand =~ s/&//g;
        $name_brand =~ s/'//g;
	    $name_brand =~ s/\<//g;
	    $name_brand =~ s/\>//g;	
	    $name_brand =~ s/\n//g;	
	    $name_brand =~ s/"//g;

	    $name_rubriki =~ s/'//g;
	    $name_rubriki =~ s/&//g;
	    $name_rubriki =~ s/\<//g;
	    $name_rubriki =~ s/\>//g;	
	    $name_rubriki =~ s/\n//g;	
	    $name_rubriki =~ s/"//g;
	    $i++;
	    my $item = { 
			 kod_podrubriki => $cat_id,
			 vendor => $name_brand, 			 
			 kod_tovar => $kod_tovar, 			
			 name_tovar => $name_tovar,			 
			 url_tovar  => $url_tovar,			 
			 desc_tovar => $desc_tovar,
             img_tovar => $img_tovar,
	     img_tovar_prev => $img_tovar_prev,
			 price => $price,
#			 tovar_model => $tovar_model,
				garranty => $garanty_tovar,
			 name_rubriki => $name_rubriki,
			 currency_ua => $currency_ua,
			 currency_v => $currency_v,
			 GalleryName => Model::SaleMod->load($kod_tovar),
			 spupdated => $spupdated, 
			 extprice => $extprice,
			 };
        	push @report_data, $item;
        }
	}}
	warn " \n\n $i -------- $self->{file} tovar ------------- \n\n";
	return \@report_data;
}




sub catalog_xls_csv_data(){
	my $self = shift;
	warn "\n\n\n xls_csv_data() $self->{id} \n\n\n";
	use Model::SaleMod;
	use Model::Currency;
	use Model::Category;
	use Model::Brand;
	my $currency_v = Model::Currency->load($self->{currency});

	my @report_data;
	my $sth = $db->prepare("select cl.id,cl.price,cc.idCat,cc.brands,cc.mods,cc.extprice FROM catalog cl INNER JOIN catalogCategory cc ON cl.id = cc.idCatalog where cc.isPublic = 1 AND cc.deleted != 1 AND cl.deleted = 0 AND cl.isPublic = 1 and cl.id = ?");
    $sth->execute($self->{id});
    while (my ($id, $price,$idc,$brands,$mods,$extprice) = $sth->fetchrow_array){

        my $q ="select c.id, sm.id, sm.idBrand,1 as ext FROM category as c INNER JOIN salemods sm ON c.id = sm.idCategory INNER JOIN brands b ON sm.idBrand = b.id WHERE c.id = ? and sm.price > ? AND sm.isPublic = 1 AND sm.deleted != 1 AND c.deleted != 1 AND c.isPublic = 1";
        if ($mods ne '0'){ $q .= " and sm.id in ($mods) ";}
        elsif ($brands ne '0'){ $q .= " and sm.idBrand in ($brands) ";}
        else {}
        $q .=" ORDER BY c.name,sm.name";
        my $sth = $db->prepare($q);
        $sth->execute($idc,$price);
	    while (my ($cat_id, $prod_id, $brand_id, $ext ) = $sth->fetchrow_array){

        if($ext != '0'){
	    my $salemod  	= Model::SaleMod->load($prod_id);
	    my $brand    	= Model::Brand->load($brand_id);
	    my $category 	= Model::Category->load($cat_id);
	    my $catalog	 	= $category->parent();
	    my $kod_rubriki     = $catalog->{id}; 
	    my $name_rubriki    = $catalog->{name};
	    my $catalog_main    = $category->parent(); 	
	    my $catalog_main_name = $catalog_main->{name};
 	    my  $catalog_main_id  = $catalog_main->{id};
	    my $kod_podrubriki  = $category->{id}; 
	    my $name_podrubriki = $category->{name}; 
	    my $name_brand      = $brand->{name}; 
	    my $kod_tovar 	= $salemod->{id}; 
	    my $name_tovar	= $salemod->{name}; 
	    my $url_tovar	= $cfg->{'stt_catalog'}->{'HOST'}.$salemod->{alias}.".htm";
	    my $img_tovar	= '0';
	    my $img_tovar_prev	= '0';
	    my $desc_tovar	= $salemod->{DescriptionFull}; 
	    my $garanty_tovar	= $salemod->{garanty};
	    my $priceCUR 	= $currency_v->{value};
	    my $currency	= $currency_v->{code}; 
	    my $price		= $salemod->{price} * $priceCUR;

        if ($salemod->{'idImage'} && $salemod->{'GalleryName'}){
            $img_tovar = $cfg->{'stt_catalog'}->{'HOST'}."gallery/".$salemod->{'GalleryName'}."/image_".$salemod->{'idImage'}.".png";
	    $img_tovar_prev = $cfg->{'stt_catalog'}->{'HOST'}."gallery/".$salemod->{'GalleryName'}."/image_".$salemod->{'idImage'}."_150_150.jpg";
	}
		
	    $name_rubriki =~ s/'//g;
	    $name_rubriki =~ s/\&//g;
	    $name_rubriki =~ s/\<//g;
	    $name_rubriki =~ s/\>//g;	
	    $name_rubriki =~ s/\n//g;	
	    $name_rubriki =~ s/"//g;

	    $name_tovar =~ s/"//g;
	    $name_tovar =~ s/'//g;
	    $name_tovar =~ s/\|//g;
	    $name_tovar =~ s/\&//g;
	    $name_tovar =~ s/\<//g;
	    $name_tovar =~ s/\>//g;	
	    $name_tovar =~ s/\n//g;	

	    $name_podrubriki =~ s/"//g;
	    $name_podrubriki =~ s/'//g;
	    $name_podrubriki =~ s/\&//g;
	    $name_podrubriki =~ s/\<//g;
	    $name_podrubriki =~ s/\>//g;	
	    $name_podrubriki =~ s/\n//g;	
	    
	    $desc_tovar =~ s/'//gm;
	    $desc_tovar =~ s/"//mg;
	    $desc_tovar =~ s/;//mg;
	    $desc_tovar =~ s/\|//gm;
            $desc_tovar =~ s/\\t//g;
	    $desc_tovar =~ s/\&//mg;
	  #  $desc_tovar =~ s/\<//mg;
	  #  $desc_tovar =~ s/\>//mg;	
	    $desc_tovar =~ s/\\n//gm;	
	    $desc_tovar =~ s/\n//gm;	
	    $desc_tovar =~ s/\r//gm;	
	    $desc_tovar =~ s/\ +/ /mg;	
    
	    my $item = { kod_rubriki     => $kod_rubriki, 			 
			 name_rubriki    => $name_rubriki, 			 
			 kod_podrubriki  => $kod_podrubriki, 
			 name_podrubriki => $name_podrubriki, 			 
			 name_brand      => $name_brand, 			 
			 kod_tovar       => $kod_tovar, 			
			 name_tovar      => $name_tovar,			 
			 url_tovar       => $url_tovar,			 
			 img_tovar       => $img_tovar,
			 img_tovar_prev	 => $img_tovar_prev,
			 catalog         => $catalog_main_name,
			 kod_catalog     => $catalog_main_id,
			 desc_tovar      => $desc_tovar,			 
			 garanty_tovar   => $garanty_tovar, 		 
			 priceCUR        => $priceCUR , 
			 currency        => $currency,	 
			 price           => $price 
		};
		push @report_data, $item;
              }
    }   }
	return \@report_data;
}









package Model::CatalogCategory;

use Model;
use Core::DB;
use Model::Category;
use Data::Dumper;

our @ISA = qw/Model/;
sub db_table() {'catalogCategory'}
sub db_columns() {qw/id idCatalog idCat isPublic deleted extprice subDate brands mods/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub category(){
    my $self = shift;
    $self->{_category} ||= Model::Category->load($self->{idCat});
    return $self->{_category};
}


package Model::CatalogSettings;
use Model;
use Core::DB;
use Data::Dumper;

our @ISA = qw/Model/;
sub db_table() {'catalogSettings'}
sub db_columns() {qw/id idCatalog fieldName dbName sep deleted sort isPublic format/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


package Model::CatalogSettingsDefault;
use Model;
use Core::DB;
use Data::Dumper;

our @ISA = qw/Model/;

sub db_table() {'catalogSettings'}
sub db_columns() {qw/id idCatalog fieldName dbName sep deleted sort isPublic format/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


package Model::CatalogContacts;
use Model;
use Core;
use Core::DB;
use Data::Dumper;
use HTML::TokeParser::Simple;
use Core::Price;
use Model::SaleMod;
our @ISA = qw/Model/;

sub db_table() {'catalogContacts'}
sub db_columns() {qw/id idCatalog idMod url/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


sub catalog_product_parse(){
    my $self = shift;
    my $model = Model::Catalog->load($self->{idCatalog});
    my $currency = Core->currencyByCode('UAH');

    if($model->{parse_func} eq 'yandex_parse')
    {
	####put you parser her    
    }
    
    if ($model->{parse_func} eq 'hotline_parse') 
    {
	 ####put you parser her
    }
##########################
## May bee used in future
##########################
#   my $count = @buf;
#   if ($count > 0)
#   {
#    	$self->save_parce_contact_result(\@buf) if $count > 0; 
#   } 
#   else 
#   {
#       	$mod = Model::SaleMod->load($self->{'idMod'});
#      		my $cats = $mod->catalogPrices($self->{'idCatalog'});
#       	my $first = @{$cats}[0];
#       	@buf = @{$first->{'prices'}};
#   }
#   return \@buf;
#   }
#   

}

sub save_parce_contact_result(){
    my $self = shift;
    my $buf = shift;
    my $idCatalog = $self->{idCatalog};

    my $sth = $db->prepare("delete from catalogPrices where idCatalog = ? and idMod = ?");
    $sth->execute($idCatalog,$self->{"idMod"});
    my $currency = Core->currencyByCode('UAH');
    foreach my $row  (@{$buf}){
	    my $sth = $db->prepare("insert into catalogPrices (idCatalog,idMod,price,uprice,site,top) value (?,?,?,?,?,?)");
        my $usd ;
        
if ($row->{'usd'} eq ""){$usd= $row->{'uah'} / $currency->{'value'};}else{$usd = $row->{'usd'};}  
        $sth->execute($idCatalog,$self->{"idMod"},$usd,$row->{'uah'},$row->{'site'},$row->{'top'}||0);
    }
}

package Model::CatalogPrices;
use Model;
use Core::DB;
use Data::Dumper;
use Cfg;
use Clean;

our @ISA = qw/Model/;
sub db_table() {'catalogPrices'}
sub db_columns() {qw/id idCatalog idMod price uprice site top updated/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub catalog_prices_grid(){
    $self = shift;
    my @buf;
    my $sth = $db->prepare("select sm.id 	 smid,
				   sm.name 	 smname, 
				   sm.price 	 smprice, 
				   c.name 	 cname, 
				   b.name 	 bname, 
				   min(sp.price) minspprice, 
				   max(sp.price) maxspprice, 
				   min(cp.price) mincpprice, 
				   min(cp.price) mincpprice, 
				   sm.price      smprice, 
				   max(cp.price) maxcpprice, 
				   cp.updated    cpupdated
			      FROM catalogPrices cp 
			INNER JOIN salemods sm ON cp.idMod = sm.id 
			INNER JOIN category c ON sm.idCategory = c.id
			INNER JOIN brands b ON b.id = sm.idBrand 
			 LEFT JOIN salerprices sp ON sp.idSaleMod = sm.id 
		          GROUP BY sm.id 
		          ORDER BY c.name, b.name, sm.name, sm.price;");
    $sth->execute();

    while (my $item = $sth->fetchrow_hashref){

		$item->{smname} = Clean->html($item->{smname});
		push @buf,$item;

    }	 

    return \@buf;
}

1;
