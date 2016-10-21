package Crond::HotlineParse;

sub new(){
	my $class = shift;
	
	my $this  = {
		lib_path => shift,
		log      => '',
	};

	return bless $this, $class;
}

sub log {
	my $this = shift;
	my $text = shift;

	$this->{log} .= $text."<br>";
}

sub execute {
	my $this = shift;
	use lib "$this->{lib_path}";
	use Core;
	
   # use Core::Price;
	use Model::Catalog;
	use Data::Dumper;


    my $DBhost = 'localhost';
    my $DBname = 'vkl';
    my $DBuser = 'vkl';
    my $DBpass = 'jousushow';



	my $currency = Core->currencyByCode('UAH');
	my $model = Model::Catalog->load('3','id');
	
	foreach $item (@{$model->catalog_get_xml_prod()}) {
	    my $contact = Core->catalog_get_contact('3',$item->{kod_tovar});
        if($contact->{url}){
	        my $parse   = Core->catalog_parse_contact('3',$contact->{url});
            my $value = "";
	        foreach my $pitem (@{$parse}) {
		        if(!$pitem->{usd}){
		            #$pitem->{usd} = Core::Price->getByValueUSD($pitem->{uah},$currency->{value});
                    $pitem->{usd} = $pitem->{uah}/8;
		        }
                $value .= "(3,'".$item->{kod_tovar}."','".$pitem->{usd}."','".$pitem->{uah}."','".$pitem->{site}."','".$pitem->{top}."'),";
            }
            chop($value);
            #warn Dumper($value);
            if ($value ne ''){
                
                my $edb = DBI->connect('DBI:mysql:database='.$DBname.';hostname='.$DBhost,$DBuser,$DBpass) or die 'Cannot connect to '.$DBname.':$!\n';
                $edb->do('SET NAMES cp1251');
                $edb->do('SET CHARSET cp1251');
                
                my $dsth = $edb->prepare("delete from catalogPrices where idCatalog = ? AND idMod = ?");
                $dsth->execute('3', $item->{kod_tovar});
                $dsth->finish();
                
                my $sth = $edb->prepare("insert into catalogPrices (idCatalog,idMod,price,uprice,site,top) values $value");
                $sth->execute();
                $sth->finish();
                
                $edb->disconnect;
                print $item->{kod_tovar}."\n";
            }
        }
        warn "next";
	}
}

1;
