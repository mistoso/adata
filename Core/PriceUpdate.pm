package Core::PriceUpdate;

use Data::Dumper;
use Core;
use Cfg;
use Core::DB;
use Spreadsheet::ParseExcel;
use Apache2::Upload;
use Apache2::Request;
use Encode;
use Model::Currency;
use Base::Translate;
use strict;

sub new(){
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub prepare_to_parsing(){

    my $self = shift;
    my $r = shift;
    $self->{log} .= "\n".time()."start prepare_to_parsing\n";    
    my $args = shift;

    my $settings="$args->{fcod}|$args->{fname}|$args->{fprice}|$args->{fprice_rozn}|$args->{discont}|$args->{fbrand}|$args->{fstock}|$args->{fdescription}|$args->{fcat}|$args->{'fidcat'}|$args->{'fidbrand'}";
    my $sth = $db->prepare("update salers set settings = '$settings',nostock= '$args->{nostock}' where id = '$args->{id}'");
    $sth->execute();
    
    map {$self->{$_} = $args->{$_} } keys %{$args};
    
    my $apr = Apache2::Request->new($r);
    my $upl = $apr->upload('file') or return undef;
    $self->{'attached_file'} = $upl->tempname;
    $self->{'idSaler'} = $args->{'id'};
    $self->{'file'} = "pu_".$self->{'id'}."_".time;
    
}


sub csv_to_csv(){
    
    my $self = shift;
$self->{log} .= "\n".time()."start csv_to_csv\n";
	open ("FILE",">/var/tmp/attached_prices/".$self->{file}.".csv") or print "error ssss!!!!!!!" and return undef;
	open(INPUT,$self->{'attached_file'}) or print "Can't open foo.csv, $!";
	while (<INPUT>){
	#	$/ ='\r\n';
		chomp;
  		my @row = split ";";
                print FILE "\"\",\"".$row[$self->{'fcod'}]."\",\"".$row[$self->{'fbrand'}]."\",\"".$row[$self->{'fname'}]."\",\"".$row[$self->{'fprice'}]."\",\"".$row[$self->{'fstock'}]."\",\"\",\"\",\"\",\"\",\"\"\n";
  	}
	close FILE;
}




sub xls_to_csv(){

    my $self = shift;
    $self->{log} .= "\n".time()."start xls_to_csv\n";
    my $path = '/var/tmp/attached_prices/';
    my $dir_exist = opendir(DIR,$path) or `mkdir -p $path`;closedir(DIR);
    my $count = 0;
	$self->{koding} = 'cp1251';
	$self->get_currency();

    open ("FILE",">/var/tmp/attached_prices/".$self->{file}.".csv") or print "error ssss!!!!!!!" and return undef;
	
    use Spreadsheet::ParseExcel;
    my $oBook = Spreadsheet::ParseExcel::Workbook->Parse($self->{'attached_file'}) ;
    my($iR, $iC, $oWkS, $oWkC);
	my $clist= 0;
    foreach my $oWkS (@{$oBook->{Worksheet}}) {
	$clist = $clist +1;
        for(my $iR = $oWkS->{MinRow};     defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++) {
                my ($stock,$stockcomm,$brand,$description,$category,$idBrand,$idCat);
                my $name_v = $oWkS->{Cells}[$iR][$self->{'fname'}];
                my $priceo_v = $oWkS->{Cells}[$iR][$self->{'fprice'}];
                my $cod_v = $oWkS->{Cells}[$iR][$self->{'fcod'}]; 
		
                next if ((!$name_v->{Val} && !$cod_v->{Val}) && ($self->{'maketype'} eq 'fixcode'));
                next if ((!$priceo_v->{Val} && !$cod_v->{Val}) && ($self->{'maketype'} eq 'updateprice'));            
		next if ((!$name_v->{Val} && !$cod_v->{Val}) && ($self->{'maketype'} eq 'createnew'));

		if  (($self->{'nostock'} ne '') && ($self->{'maketype'} eq 'updateprice')) {
			#$self->{log} .= $self->{'nostock'};
			my $stock_v = $oWkS->{Cells}[$iR][$self->{'fstock'}];
			$stock = $stock_v->Value if $stock_v->{Val};
			#$stock = my_code($stock);
                        my $ok=0;
                        my @expr = split (',',$self->{'nostock'});
		#	$self->{log} .= $ok."start".$stock;
                        foreach (@expr){ 
				my $exp = decode('cp1251',$_);
		#		$self->{log} .= "\n".time()."$stock =><= $exp";
				if ($stock eq $exp){ $ok = 1; }
				
				#if ($exp == '+'){$exp ='\+';}
				#if ($exp == '*'){$exp ='\*'; $self->{log} .= 31;}
				#if ($stock =~ /($exp)/){ $ok = 1;$self->{log} .= 2;}
			}
		#	$self->{log} .= $ok."show";
			next if ($ok == 1);
		#	$self->{log} .= $ok."2";
                        $stock = 1 if ($stock !~ /\d+/);
                    next if $stock eq '0';
		#	$self->{log} .= $stock;
                }else{
                    $stock = 1;
                }
		if ($self->{'fstockcomm'} > '0'){
			my $stockcomm_v  = $oWkS->{Cells}[$iR][$self->{'fstockcomm'}];
			$stockcomm = $stockcomm_v->Value if $stockcomm_v->{Val};
		#	$self->{log} .= $stockcomm_v->{Val};
			$stockcomm = my_code($stockcomm);
		}
                $name_v->{_Value} =~ s/\"//gm;
                $name_v->{_Value} =~ s/\'//gm;
                $name_v->{_Value} =~ s/\*//gm;
                $name_v->{_Value} =~ s/\_//gm;
                $name_v->{_Value} =~ s/^\s*?//g;
#               $name_v->{_Value} =~ s/\s*?//g unless $self->{'maketype'} eq 'createnew';
                $name_v->{_Value} =~ s/\*/x/gm;
		$name_v->{_Value} =~ s/\t/ /gm;
		$name_v->{_Value} =~ s/\ +/ /gm;
		$name_v->{_Value} =~ s/  / /gm;
                my $name = $name_v->Value if $name_v->{Val};    
		$name =~ s/\t//gm;
		$name =~ s/  / /gm;
                $name =~ s/^\ //g;
		$cod_v->{_Value} =~ s/\*/x/gm;
                $cod_v->{_Value} =~ s/\)//gm;
                $cod_v->{_Value} =~ s/\(//gm;
                $cod_v->{_Value} =~ s/\.//gm;
                $cod_v->{_Value} =~ s/\'//gm;
                $cod_v->{_Value} =~ s/\"//gm;
                $cod_v->{_Value} =~ s/\_//gm;
		$cod_v->{_Value} =~ s/\s*?//gm;
                $cod_v->{_Value} =~ s/\\//gm;
		$cod_v->{_Value} =~ s/\t/ /gm;
		$cod_v->{_Value} =~ s/\ +/ /gm;
                $cod_v->{_Value} =~ s/\ //gm;
                $cod_v->{_Value} =~ s/\+//gm;
                my $cod = $cod_v->Value if $cod_v->{Val};
		$cod =~ s/\t//gm;

                my $price_opt = $priceo_v->Value if $priceo_v->{Val};

                if ($self->{koding} eq 'cp1251'){$name = my_code($name);$cod = my_code($cod);}
                if ($price_opt =~ /\,/s){
                    if ($price_opt =~ /\./s){$price_opt =~ s/\,//;}
                    elsif ($price_opt =~ /.+\,.{3}/s){$price_opt =~ s/\,//;}
                    else {$price_opt =~ s/\,/\./;}
                }
		$price_opt =~ s/[^\d\.\,]//gm;
		$price_opt  = $price_opt / $self->{'curs'} ;

		#################################
                $price_opt  = sprintf('%.'.$cfg->{'temp'}->{'price_coin'}.'f',$price_opt);

                if ($self->{'fbrand'} != ''){
                    my $brand_v = $oWkS->{Cells}[$iR][$self->{'fbrand'}];
                    $brand = $brand_v->Value if $brand_v->{Val};
                    if ($self->{koding} eq 'cp1251'){$brand = my_code($brand);}
                    $brand = "\L$brand";
                    $brand = "\u$brand";
                }
		if ($self->{'fidbrand'} != ''){
			my $idBrand_v = $oWkS->{Cells}[$iR][$self->{'fidbrand'}];
			$idBrand = $idBrand_v->Value if $idBrand_v->{Val};	
		}
		#$self->{log} .= "\n".time()."<<".$self->{'fdescription'}.">>";
                if (defined($self->{'fdescription'}) && ($self->{'fdescription'} != '')){
		
                    my $description_v = $oWkS->{Cells}[$iR][$self->{'fdescription'}];
                    $description_v->{_Value} =~ s/\"/&quot;/g;
                    $description = $description_v->Value if $description_v->{Val};
                    if ($self->{koding} eq 'cp1251'){$description = my_code($description);}
			$description =~ s/"//gm;
                }
                if($self->{'fprice_rozn'} !='') {
                    my $price_rozn_v = $oWkS->{Cells}[$iR][$self->{'fprice_rozn'}];
                    my $price_rozn = $price_rozn_v->Value if $price_rozn_v->{Val};
                    if ($price_rozn =~ /\,/s){
                        if ($price_rozn =~ /\./s){$price_rozn =~ s/\,//;}
                        elsif ($price_rozn =~ /.+\,.{3}/s){$price_rozn =~ s/\,//;}
                        else {$price_rozn =~ s/\,/\./;}
                    }
		$price_rozn  = $price_rozn / $self->{'curs'};
                    $price_rozn = sprintf('%.'.$cfg->{'temp'}->{'price_coin'}.'f',$price_rozn);
                    $price_opt  = "$price_opt|$price_rozn";
                }

                if($self->{'fcat'} != ''){
                    my $category_v = $oWkS->{Cells}[$iR][$self->{'fcat'}];
                    $category = $category_v->Value if $category_v->{Val};
                    if ($self->{koding} eq 'cp1251'){$category = my_code($category);}
                }
		if (($self->{'fidcat'} == 0) || ($self->{'fidcat'} > 0)){
			my $idCat_v = $oWkS->{Cells}[$iR][$self->{'fidcat'}];
			$idCat = $idCat_v->Value if $idCat_v->{Val};	
		}
                

                if($cod && $name && (($self->{'maketype'} eq 'fixcode') or ($self->{'maketype'} eq'downlistnew'))){
                    $count++;
                    $name =~ s/ *$//g;
                    
                 # $self->{log} .=  "\"$cod\",\"$brand\",\"$name\",\"$price_opt\",\"$stock\",\"$description\",\"$category\",\"\",\"\",\"\"\n";
                    print FILE "\"\",\"$cod\",\"$brand\",\"$name\",\"$price_opt\",\"$stock\",\"$description\",\"$category\",\"\",\"\",\"\"\n";
                }
                elsif($cod && $name && ($self->{'maketype'} eq 'createnew')){
                    $count++;
                    $name =~ s/ *$//g;
                    
                  #  $self->{log} .=  "\"$cod\",\"\",\"$name\",\"$price_opt\",\"\",\"$description\",\"\",\"$idBrand\",\"$idCat\",\"\"\n";
                    print FILE "\"\",\"$cod\",\"$brand\",\"$name\",\"$price_opt\",\"$stock\",\"$description\",\"\",\"$idBrand\",\"$idCat\",\"\"\n";
                }
                elsif($cod && $price_opt && ($self->{'maketype'} eq 'updateprice')){
                    $count++;
                   #    if ($self->{'idSaler'} == '1') {  print "\"\",\"$cod\",\"$brand\",\"$name\",\"$price_opt\",\"$stock\",\"\",\"\",\"\",\"\",\"$stockcomm\"\n";}
                    print FILE "\"\",\"$cod\",\"$brand\",\"$name\",\"$price_opt\",\"$stock\",\"\",\"\",\"\",\"\",\"$stockcomm\"\n";
                }
        }
     last if ($clist == $self->{'page'}); 
  }
    close FILE;
    $self->{log} .=  "+++++".$count;
    $self->{'pos_in_price'} = $count;
    #print Dumper($self);

    return $self;
}             


sub csv_to_mysql(){

    my $self = shift;
    $self->{log} .= "\n".time()."start csv_to_mysql\n";    
    my $tname = $self->{'file'} ;

    my $csth = $db->prepare("CREATE TABLE `$tname` ( 
  	id mediumint(6) unsigned NOT NULL auto_increment PRIMARY KEY ,
	code varchar(100) not null , 
	brand varchar(25), 
	modname varchar(255) not null, 
	price varchar(25) NOT NULL default '0', 
	instock int(5), 
	description text,
	category varchar(35),
	idBrand int(10),
	idCategory int(10),
	stockcomm varchar(20)) ENGINE=Aria DEFAULT CHARSET=cp1251");$csth->execute();

    my $isth = $db->prepare("LOAD DATA LOCAL INFILE '/var/tmp/attached_prices/$tname.csv' INTO TABLE $tname 
		CHARACTER SET 'cp1251' 
		FIELDS TERMINATED BY \',\' 
		ENCLOSED BY \'\"\' 
		LINES TERMINATED BY \'\n\';"); $isth->execute();

    my $asth = $db->prepare("ALTER TABLE $tname ADD COLUMN (
	oldprice decimal(9,2) NOT NULL default '0.00', 
	spid varchar(20) null, 
	idMod varchar(10) null)"); $asth->execute();

    my $usth = $db->prepare("UPDATE $tname as tmp 
	INNER JOIN salerprices as sp ON tmp.code = sp.uniqCode 
	SET tmp.oldprice = sp.price , 
		tmp.spid = sp.id , 
		tmp.idMod = sp.idSaleMod 
	WHERE sp.idSaler = $self->{idSaler}"); $usth->execute();
    my $ksth = $db->prepare("alter table $tname add key idSaleMod(idMod)");$ksth->execute();
   
return 1;
}

sub get_info_for_list(){    

    my $self = shift;
    $self->{log} .= "\n".time()."start get_info_for_list\n";    
    my $tname = $self->{'file'};

    #my $sth = $db->prepare("select * from $tname where idMod is null"); $sth->execute();
    #while (my $item = $sth->fetchrow_hashref){
    #    push @{$self->{newlist}},$item;
    #}

    my $sth = $db->prepare("select count(*) from $tname where idMod is null");$sth->execute();
    $self->{newlist_size} = $sth->fetchrow_array;
    my $sth = $db->prepare("select count(*) from $tname");$sth->execute();
    $self->{list_size} = $sth->fetchrow_array;

    #my $sth = $db->prepare("select * from $tname where idMod is not null");$sth->execute();
    #while (my $item = $sth->fetchrow_hashref){
    #    push @{$self->{donelist}},$item;
    #}    
 print Dumper($self) if $self->{exit};
    exit if $self->{exit};
}        

sub for_update(){

	my $self = shift;	
    $self->{log} .= "\n".time()."statr for update";
	my $tname = $self->{'file'}; 
	my $nsth = $db->prepare("select count(*) from $tname where idMod is null");
	$nsth->execute();
	my $n = $nsth->fetchrow_array;
	$self->{newlist_size} = $n;
    #print $self->{newlist_size};
	my $sth = $db->prepare("DELETE FROM $tname where idMod is null "); $sth->execute();
	my $sth = $db->prepare("alter table $tname drop column description "); $sth->execute();
    
	my $dsth = $db->prepare("select count(*) from $tname ");$dsth->execute();
	my $n = $dsth->fetchrow_array;
	$self->{done_size} = $n;
    #print $self->{done_size};
}

sub set_discont(){
	my $self = shift;	
	$self->{log} .= "\n".time()."set discount";
	my $tname = $self->{'file'};
    	my $usth = $db->prepare("UPDATE $tname as tmp INNER JOIN salemods as s ON tmp.idMod = s.id SET tmp.idBrand = s.idBrand"); 
	$usth->execute();
    	my $bsth = $db->prepare("select idBrand,discont from salerprices_brand_discont where idSaler = ?"); 
	$bsth->execute($self->{idSaler});
	while (my ($idBrand,$value) = $bsth->fetchrow_array()){
    		my $ubsth = $db->prepare("UPDATE $tname set price = (price - price*(?/100)), idBrand = 0 where idBrand = ?"); 
		$ubsth->execute($value,$idBrand);
	}
	if ($self->{'discont'} >0){
    		my $udsth = $db->prepare("UPDATE $tname set price = (price - price*(?/100)) where idBrand > 0"); 
		$udsth->execute($self->{'discont'});
	}
}

sub set_saler_prices(){

    my $self = shift;
    my $tname = $self->{'file'};
    $self->{log} .= "\n".time()."start set_saler_prices\n";
    if ($self->{'fprice_rozn'} ne ''){
       my $sth = $db->prepare("alter table $tname add column price1 decimal(9,2) NOT NULL default '0.00' after price");$sth->execute();
       my $sth = $db->prepare("update $tname set price1=substring_index(price,'|',-1),price=substring_index(price,'|',1)");$sth->execute();
       my $sth = $db->prepare("alter table $tname modify column price decimal(9,2) NOT NULL default '0.00'");$sth->execute();
    }
    if (($self->{'del_all'} eq '1')||($self->{'del_all'} eq 'on')){
        my $sthp = $db->prepare("UPDATE salerprices set price = '0',updated = CURRENT_TIMESTAMP,stockComment = '' where idSaler = ?");$sthp->execute($self->{'idSaler'});
    } 
    my $th_ext_update = $db->prepare("UPDATE salerprices as sp INNER JOIN $tname as tmp  on sp.id=tmp.spid SET sp.price = tmp.price,sp.updated = CURRENT_TIMESTAMP,sp.instock = tmp.instock,sp.stockComment=tmp.stockcomm WHERE tmp.instock > 0 "); $th_ext_update->execute();
    
    return 1;
}

sub set_saler_min_price(){

	my $self = shift;
	$self->{log} .= "\n".time()."start set_saler_min_price\n";
	my $tname = $self->{'file'};
	if (($self->{"del_all"} eq "1")||($self->{'del_all'} eq 'on')){
		my $sth_idSaleMod = $db->prepare("insert into $tname (spid,idMod,price,code) select sp.id,sp.idSaleMod,sp.price,sp.id from salerprices as sp left outer join $tname as tmp on tmp.idMod = sp.idSaleMod where sp.idSaler = ? and tmp.idMod is null ");
		$sth_idSaleMod->execute($self->{'idSaler'});
	}
	my $sth = $db->prepare("alter table $tname add column (margin decimal(9,2) NOT NULL default '0.00', isgen varchar(2), minp varchar(10),do boolean not null,brule varchar(10),percentage int(1) default 0 )"); $sth->execute();

	#############################
	#my $sth = $db->prepare("update $tname as tmp inner join salerminprice as smp on tmp.idMod = smp.idSaleMod set tmp.do = 1 where (tmp.price <= smp.price and tmp.price != 0) or (tmp.price > 0 and smp.idSaler = ?) or (tmp.price > 0 and ((smp.price = 0) or (smp.price is null)))");$sth->execute($self->{'idSaler'});
	#my $sth = $db->prepare("update $tname as tmp left outer join salerminprice as smp on tmp.idMod = smp.idSaleMod set tmp.do = 1 where smp.idSaleMod is null");$sth->execute();
		### dell rows wich not need (do = 0)
		#my $dsth = $db->prepare("delete from $tname where do != 1");$dsth->execute();
    	#############################
		
	my $th_prepare = $db->prepare("UPDATE $tname as tmp INNER JOIN salemods as s ON s.id = tmp.idMod SET tmp.isgen = s.priceAutogen, tmp.idCategory = s.idCategory,tmp.idBrand = s.idBrand "); $th_prepare->execute();
	my $th_get_min_sal =$db->prepare("UPDATE $tname as tmp INNER JOIN subprices as sp ON tmp.idCategory=sp.cat_id set tmp.margin = IFNULL(sp.value,0),brule = sp.salers_id WHERE sp.max_price>=tmp.price and sp.min_price<=tmp.price and tmp.idBrand = sp.brand_id and sp.salers_id is not null"); $th_get_min_sal->execute();
	my $sth_idSaleMod = $db->prepare("select idMod,brule from $tname ");$sth_idSaleMod->execute();
	while (my ($id,$salers_id) =$sth_idSaleMod->fetchrow_array()){
		my ($idSaler,$updated,$mprice); 
		if ($salers_id){
			my $budlo1= $db->prepare("SELECT idSaler,updated,price FROM salerprices WHERE price = (SELECT min(price) FROM salerprices WHERE price > 0 AND idSaleMod = ? and idSaler in (?) GROUP BY idSaleMod) AND idSaleMod = ? and idSaler in (?)");$budlo1->execute($id,$salers_id,$id,$salers_id);
			($idSaler,$updated,$mprice) = $budlo1->fetchrow_array();
		}
		unless ($mprice){
				my $th_minprice =$db->prepare("SELECT idSaler,updated,price FROM salerprices WHERE price = (SELECT min(price) FROM salerprices WHERE price > 0 AND idSaleMod = ? GROUP BY idSaleMod) AND idSaleMod = ?");
				$th_minprice->execute($id,$id);
				($idSaler,$updated,$mprice) = $th_minprice->fetchrow_array();
				unless ($mprice){
					$mprice = '0';
				}
		}
		$mprice = sprintf('%.'.$cfg->{'temp'}->{'price_coin'}.'f',$mprice);
		my $sth = $db->prepare('REPLACE salerminprice SET idSaleMod = ?, idSaler = ?, price = ?, updated = ?'); $sth->execute($id,$idSaler,$mprice,$updated);
	}
	my $th_min_price = $db->prepare("update $tname as tmp INNER JOIN salerminprice as smp on tmp.idMod = smp.idSaleMod SET tmp.minp = smp.price"); $th_min_price->execute();
	
	return 1;
}

sub set_salemod_price(){

	my $self = shift;
	$self->{log} .= "\n".time()."start set_salemod_price\n";
	my $tname = $self->{'file'};
	unless ($self->{'fprice_rozn'} ne ''){#### avtogeneraciya dlya vseh tovarov (dlya priceautogen = 0 ) 
		my $dsth = $db->prepare("delete from $tname where isgen != 1");$dsth->execute();
	} 
    my $thc = $db->prepare("UPDATE salemods as s INNER JOIN $tname as tmp on s.id = tmp.idMod SET s.price = '0',s.coment = '' "); $thc->execute();
    
    if ($self->{'fprice_rozn'} ne ''){
        my $th_priceupdate = $db->prepare("UPDATE salemods as s INNER JOIN $tname as tmp on s.id = tmp.idMod SET s.price = tmp.price1 where tmp.price1 != '' "); $th_priceupdate->execute();
    }else{
        my $th_getvalueb = $db->prepare("UPDATE $tname as tmp INNER JOIN subprices as sp ON tmp.idCategory=sp.cat_id SET tmp.margin = IFNULL(sp.value,0),tmp.percentage = sp.percentage WHERE sp.max_price>=tmp.minp and sp.min_price<=tmp.minp and tmp.idBrand = sp.brand_id and tmp.margin =0 "); $th_getvalueb->execute();
        my $th_getvalue = $db->prepare("UPDATE $tname as tmp INNER JOIN subprices as sp ON tmp.idCategory=sp.cat_id SET tmp.margin = IFNULL(sp.value,15),tmp.percentage = sp.percentage WHERE sp.max_price>=tmp.minp and sp.min_price<=tmp.minp and sp.brand_id = '0' and tmp.margin = 0 "); $th_getvalue->execute();
        my $th_priceupdate = $db->prepare("UPDATE salemods as s INNER JOIN $tname as tmp on s.id = tmp.idMod SET s.price = IF(tmp.percentage = 1,ROUND(tmp.minp + (tmp.minp*(tmp.margin/100)),".$cfg->{'temp'}->{'price_coin'}."),ROUND(tmp.margin + tmp.minp,".$cfg->{'temp'}->{'price_coin'}." )) where tmp.minp > 0 "); $th_priceupdate->execute();
    }
    my $th_public_base = $db->prepare("UPDATE salemods as s INNER JOIN $tname as tmp on s.id = tmp.idMod SET s.isPublic = '1' where s.price >= 1"); $th_public_base->execute();

    my $th_unpublick_zero = $db->prepare("UPDATE salemods as s INNER JOIN $tname as tmp  on s.id = tmp.idMod SET s.isPublic = '0' where s.price = '0' and s.priceAutogen ='1' and s.coment = ''"); $th_unpublick_zero->execute();    
    #my $arc_sth = $db->prepare("insert into price_arch (kod_tovar,last_update,mt_cena) select idMod,CURDATE(),ROUND(margin+minp,".$cfg->{'temp'}->{'price_coin'}.") from $tname"); $arc_sth->execute();
    return 1;
}

sub drop_pu_table(){
	my $self = shift;
	$self->{log} .= "\n".time()."drop pu table\n";
	my $sth = $db->prepare("drop table ".$self->{'file'});
	$sth->execute(); 
}

sub for_fix(){

	my $self = shift;
    $self->{log} .= "\n".time()."statr for fix";	
	my $tname = $self->{'file'}; 
	my $nsth = $db->prepare("select count(*) from $tname where idMod is not null");
	$nsth->execute();
	my $n = $nsth->fetchrow_array;
	$self->{fixed_size} = $n;
	my $sth = $db->prepare("DELETE FROM $tname where idMod is not null "); $sth->execute();
    
	my $dsth = $db->prepare("select count(*) from $tname ");$dsth->execute();
	my $n = $dsth->fetchrow_array;
	$self->{new_size} = $n;
    #print $self->{new_size};
    $self->get_new();
    
}
sub get_liked_code(){
    my $self = shift;
    my $code = shift;
    $self->{log} .= "\n".time()."statr get_liked_code";
    my @buf;
    my $sth = $db->prepare("select distinct(idSaleMod) from salerprices where uniqCode like '%".$code."%'");
    $sth->execute();
    while (my $id = $sth->fetchrow_array){
        my $sth = $db->prepare("select s.name,s.id,c.name as cname from salemods as s inner join category as c on c.id = s.idCategory where s.id = ?");
        $sth->execute($id);
        push @buf,$sth->fetchrow_hashref();
    }
    return \@buf;
}

sub get_liked_sname(){
    my $self = shift;
    my $frase = shift;
    my $total_found ;
    use Cfg;
    use Sphinx::Search;
    my @buf;
    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});
    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });
        $sp->SetMatchMode( SPH_MATCH_ALL );
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        my $result = $sp->Query($frase,"");
        my $total_found = $result->{total};
        if ($total_found eq '0' and scalar(split(//,$frase)) > 2) {
            #print "++".scalar(split(//,$frase))."++";
            $result = $sp->Query('*'.$frase.'*','e');
        }
        $sp->Close();
        #print Dumper($result);
        foreach (@{$result->{matches}}) {
            push @buf,Model::SaleMod->load($_->{doc});
        }
    }
    return  \@buf;
}

sub list_of_fixed() {

        my $self = shift;
        my $id = shift;
    my @buf;
    #$self->{log} .= "\n".time()."statr list_of_fixed";
    my $sth = $db->prepare("select sp.id as id_p,sp.idSaleMod,sp.uniqCode,sm.id as id_m,sm.name,sm.price,c.name as cname from salerprices as sp inner join salemods as sm on sm.id=sp.idSaleMod inner join category as c on sm.idCategory = c.id where sp.idSaler = ? and sp.uniqCode is not null order by c.name,sm.name");
        $sth->execute($id);
        while (my $item = $sth->fetchrow_hashref){
                push @buf,$item;
        }

    return \@buf;
}
sub unfix_pos() {

    my $self = shift;
    my $in = shift;

#    $self->{log} .= "\n".time()."statr unfix_pos";
#    $self->{log} .= $in;

    my $sth = $db->prepare("delete from salerprices where id in ($in)");
    $sth->execute();

    return 1;
}

sub set_statistic(){

	my $self = shift;
	$self->{log} .= "\n".time()."set statistic";
	my $sth = $db->prepare('insert into salerprices_updates (idSaler,updnum,newnum,idOperator) value (?,?,?,?)');
	$sth->execute($self->{'idSaler'},$self->{'done_size'},$self->{'newlist_size'} || $self->{'createdlist_size'} ,$self->{'idOperator'} || '1');
	$self->drop_pu_table();
}

sub get_info_for_fixcode (){
    my $self = shift;
    $self->{log} .= "\n".time()."start get_info_for_fixcode \n";

    foreach my $item (@{$self->{donelist}}){
        $item->{model} = Model::SaleMod->load($item->{idMod});
    }
    foreach my $item (@{$self->{newlist}}){
        $item->{model} = Model::SaleMod->load($item->{idMod});
    }

    return $self;
}

sub fixcodes(){
    my $self = shift;
    my $args = shift;
    my $buf = {};
    my $h = {};
    my $tname = $args->{'file'};
    my $saler = Model::Saler->load($args->{'idSaler'});
    foreach my $key (keys %$args){
        next if ($key =~ /^like/);
        my ($idSaler,$code) = ($key =~ /^p(.+)_(.+)$/);
        $self->{$key} = $args->{$key} unless $code and $idSaler;
        next unless $code and $idSaler;
        my $ignore = $args->{'i'.$idSaler.'_'.$code};
        my $id = $args->{$key};
        if ($ignore){}
        else {
            next unless $id;
            my $salemod = Model::SaleMod->load($id) or next;
            $saler->addCategory($salemod->{'idCategory'});
            undef $args->{$key};
            my $sth = $db->prepare('REPLACE salerprices SET uniqCode = ? , idSaleMod = ?,idSaler = ?');
            $sth->execute($code,$salemod->{'id'},$idSaler) or $self->{log} .= "\n".time()."failed set the key";
            my $sth = $db->prepare("update $tname set idMod = ? where code = ?");
            $sth->execute($id,$code);
        }
    }
    return $self;
}

sub next_page_for_fix(){
    my $self = shift;
    if (($self->{'new_size'} / 20) > $self->{'page'}){
        $self->{'page'}++;
        $self->get_new($self->{'page'}++);

    }else{}
    return $self;
}        

sub get_new(){
    my $self = shift;
    my $page = shift || 1; #huinya
    my $count = 0;
    my $tname = $self->{'file'};
    my $enum = 20 * ($page - 1);  
    $self->{'page'} = $page;
    my $sth = $db->prepare("Select * from $tname limit ?,?");$sth->execute($enum,20);
    while (my $item = $sth->fetchrow_hashref){
        push @{$self->{newlist}},$item;
        $count++;
    }
    my $sth = $db->prepare("select count(*) from $tname where idMod is not null");
    $sth->execute();
    $self->{'new_fixed'} = $sth->fetchrow_array();
    if ($count < 20){
        $self->{'last_page'} = 1;
    }
    return $self;
}

sub my_code(){
    use Encode;
    my $word = shift;
    my $enc= encode('cp1251',$word);
    return $enc;
}

sub get_item(){
    my $self = shift;
    my $code = shift;
    my $tname = shift;

    my $sth = $db->prepare("select * from $tname where code = ?");
    $sth->execute($code);
    my $item = $sth->fetchrow_hashref();
    
    return $item;
}

sub get_binded_product(){
    my $self = shift;
    my $tname = $self->{'file'};
    my $count = 0;
    my $sth = $db->prepare("select * from $tname where idMod is not null ");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        $item->{'product'} = Model::SaleMod->load($item->{'idMod'}); 
        push @{$self->{bindedlist}},$item;
        $count++;
    }
    $self->{'bindedcount'} = $count;
    my $sth = $db->prepare("select count(*) from $tname where idMod is null");
    $sth->execute();
    $self->{'newlist_size'} = $sth->fetchrow_array();
    #my $sth = $db->prepare("drop table $tname");
    #$sth->execute();
    return $self;
}

sub create_new(){
	
	my $self = shift;
	my $tname  = $self->{'file'};

	use Model::SaleMod;
	use Model::Category;
	use Model::Brand;
	use Data::Dumper;
#print Dumper($self);
	my $sth = $db->prepare("alter table $tname add column isNew int(1) default 0");
	$sth->execute();

	my $saler = Model::Saler->load($self->{'idSaler'});
    	my $sth = $db->prepare("select * from $tname where idMod is null");
    	$sth->execute();
	my $i;
    	while (my $item = $sth->fetchrow_hashref){
        	my $model = Model::SaleMod->new();
        	my $category = Model::Category->load($item->{'idCategory'}) or next;
        	my $brand = Model::Brand->load($item->{'idBrand'}) or next;
#print Dumper($category);print Dumper($brand);		
		my $name = $item->{'modname'};
		$name = $brand->{'name'}." ".$name if $self->{'add_brand_name'} eq 'append';
		$model->{'alias'} = Base::Translate->translate($name);
		$model->{'name'} = $name;
		#$model->{'name'} = $model->{'name'}.'mi' if $saler->{'id'} eq '25';
		$model->{'name'} =~ s/\t/ /;
		$model->{'name'} =~ s/\ +/ /;
		my $old_mod = Model::SaleMod->load($model->{'alias'},'alias');
		unless ($old_mod->{'id'}){
			$old_mod= Model::SaleMod->load($model->{'name'},'name');
		}
		my $isNew = 0;
		unless ($old_mod->{'id'}){
			$model->{'idBrand'}=$brand->{'id'};
			$model->{'idCategory'}=$category->{'id'};
			$model->{'DescriptionFull'}=$item->{'description'};
			$model->{'Description'}=$item->{'description'};
			$model->{'priceAutogen'}=1;
			
			$isNew = 1;
		}else{  
			$model = $old_mod;
		}
		unless ($model->save()){
			$self->{log} .= 'Failed'.$model->errs." ".$item->{'code'};
			next;
		}
		
		
		my $sth = $db->prepare("select id from salerprices where idSaler = ? and idSaleMod = ?");
		$sth->execute($saler->{'id'},$model->{'id'});
		my $id = $sth->fetchrow_array();
		unless ($id){		
			$saler->addCategory($category->{'id'});
			my $salerprices = Model::SalerPrices->new();
			$salerprices->{'idSaler'} = $saler->{'id'};
			$salerprices->{'idSaleMod'} = $model->{'id'};
			$salerprices->{'uniqCode'} = $item->{'code'};
			
			$salerprices->{'price'} = $item->{'price'};
			$salerprices->save();
		}
		my $sth = $db->prepare("update $tname set idMod = ?,isNew = ? where code = ?");
		$sth->execute($model->{'id'},$isNew,$item->{'code'});
		$i++;
	}
	$self->{'createdlist_size'} = $i;
	
	return $self;
}

sub create_new_gala(){
	
	my $self = shift;
	my $tname  = $self->{'file'};
	$self->{log} .= "\n".time()."create_new_gala\n";
	return 1 unless $self->{'create_new_gala'};
	use Model::SaleMod;
	use Model::Category;
	use Model::Brand;
	use Data::Dumper;

	my $array->{id} = 1;
	my $sth = $db->prepare("alter table $tname add column isNew int(1) default 0");
	$sth->execute();

	my $saler = Model::Saler->load($self->{'idSaler'});
	my $sth = $db->prepare("select * from $tname where idMod is null ");
    $sth->execute();
	my ($i,$k) = (0,0) ;
    while (my $item = $sth->fetchrow_hashref){
		$k += 1;
        	my $model = Model::SaleMod->new();
        	my $category = Model::Category->load($item->{'idCategory'}) or {};
        	my $brand = Model::Brand->load($item->{'idBrand'}) or {};

		$model->{'alias'} = Base::Translate->translate($item->{'modname'});
		$model->{'name'} = $item->{'modname'};
		$model->{'name'} =~ s/\t/ /;
		$model->{'name'} =~ s/\ +/ /;
		$model->{'mpn'} = $item->{'code'};
		my $old_mod = Model::SaleMod->load($model->{'alias'},'alias');
		
		if (!$old_mod->{'id'}){
			$old_mod= Model::SaleMod->load($model->{'name'},'name');
		}
		my $isNew = 0;
		
		if (!$old_mod->{'id'}){
			$model->{'idBrand'}= $brand->{'id'} || 1;
			$model->{'idCategory'}='2378';############## magiya chisel
			#$model->{'DescriptionFull'}=$item->{'description'};
			#$model->{'Description'}=$item->{'description'};
			$model->{'priceAutogen'}=1;
			$model->{'mark'}=1;
			$isNew = 1;
		}else{  
			$model = $old_mod;
		}
		unless ($model->save()){
			$self->{log} .= 'Failed'.$model->errs." ".$item->{'code'};
			next;
		}
		#if ($self->{content} ne '0' && !($old_mod->{id})){
		#	unless ($self->{content_user}){
		#		$self->{content_user} = Model::Content::User->load($self->{content});
		#	}
		#	Model::Content::Task->makeTask($self->{content_user}, $model,'');
		#}
		
		my $sth = $db->prepare("select id from salerprices where idSaler = ? and idSaleMod = ?");
		$sth->execute($saler->{'id'},$model->{'id'});
		my $id = $sth->fetchrow_array() or undef;
		if (!$id){		
			$saler->addCategory($category->{'id'});
			my $salerprices = Model::SalerPrices->new();
			$salerprices->{'idSaler'} = $saler->{'id'};
			$salerprices->{'idSaleMod'} = $model->{'id'};
			$salerprices->{'uniqCode'} = $item->{'code'};
			
			$salerprices->{'price'} = $item->{'price'};
			$salerprices->save();
		}
		my $sth = $db->prepare("update $tname set idMod = ?,isNew = ? where code = ?");
		$sth->execute($model->{'id'},$isNew,$item->{'code'});
		$i += 1;
	}
	$self->{'createdlist_size'} = $i;
	$self->{log} .= "\n".time()." created => $i from $k \n";
	
	return $self;
}

sub set_new_name(){
	my $self = shift;
	my $tname  = $self->{'file'};
	$self->{log} .= "\n".time()."set_new_name\n";
	if ($self->{'update_name'} eq 1){
		my $bname = $self->{'append_brand_name'} eq 'append' ? 1 : 0;
		
		my $sthc = $db->prepare("select count(*) from salemods s inner join $tname tmp on s.id =tmp.idMod inner join brands b on b.id = s.idBrand where  s.name != IF(?,concat(b.name,' ',tmp.modname),tmp.modname)");
		$sthc->execute($bname);
		$self->{'renamedlist_size'} = $sthc->fetchrow_array() or 0;
		if ($self->{'renamedlist_size'}){	
			my $sth = $db->prepare("update salemods s inner join $tname tmp on s.id =tmp.idMod inner join brands b on b.id = s.idBrand set s.name = IF(?,concat(b.name,' ',tmp.modname),tmp.modname) where s.name != IF(?,concat(b.name,' ',tmp.modname),tmp.modname)");
			$sth->execute($bname,$bname);
		}
		$self->{log} .= "\n".time()."updated new name ".$self->{'renamedlist_size'}."\n";
	}
	return $self;
}

sub update_salemod_info(){
	my $self = shift;
	my $tname  = $self->{'file'};
	$self->{log} .= "\n".time()."set_new_name\n";
	if ($self->{'update_salemod_info'} eq 1){
	    # description
	    
	    #fulldescription
	    
	    #oprice
	    
	    #image
	    
	    
		#$self->{'renamedlist_size'} = $sthc->fetchrow_array() or 0;
		if ($self->{'renamedlist_size'}){	
			my $sth = $db->prepare("update salemods s inner join $tname tmp on s.id =tmp.idMod inner join brands b on b.id = s.idBrand set s.name = IF(?,concat(b.name,' ',tmp.modname),tmp.modname) where s.name != IF(?,concat(b.name,' ',tmp.modname),tmp.modname)");
			$sth->execute();
		}
		$self->{log} .= "\n".time()."updated new name ".$self->{'renamedlist_size'}."\n";
	}
	return $self;
}

sub set_salemod_comment(){
	my $self = shift;
	my $tname  = $self->{'file'};
	if ($self->{'set_salemod_comment'} eq 'on'){
    		my $sth = $db->prepare("update salemods s inner join $tname tmp on s.id = tmp.idMod set s.coment = tmp.stockcomm where LENGTH(tmp.stockcomm) > 2 ");
    		$sth->execute();
	}
	return $self;
}

sub get_currency(){
	my $self = shift;
	$self->{'curs'} = 1;

	if (($self->{'idCurrency'} > 0) && ($self->{'idCurrency'} != 2 )){	
		my $cur = Model::Currency->load($self->{'idCurrency'});
		$self->{'curs'} = $cur->{'value'};
	}
  
	return $self;
}

sub create_list_of_new(){
	my $self = shift;
	my $end = shift;
	
	my $sth = $db->prepare("select * from ".$self->{'file'}." where idMod is null");
    	$sth->execute();
    	unlink($cfg->{'PATH'}->{'ext'}."/unbinded.csv");
	open ("FILE",">".$cfg->{'PATH'}->{'ext'}."/unbinded.csv") or print "error ssss!!!!!!!" and return undef;
	
	while (my $item = $sth->fetchrow_hashref){
		print FILE "\"".$item->{'category'}."\";\"".$item->{'brand'}."\";\"".$item->{'code'}."\";\"".$item->{'modname'}."\";\"".$item->{'description'}."\"\n";
  	}
	close FILE;
    	print '<a href="/ext/unbinded.csv" target="_blanc">unbinded</a>';
	return $self;
	

}


1;
