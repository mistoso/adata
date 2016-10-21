package Crond::GenerateCSVFromSQL;
use strict; use warnings;
 use Time::HiRes; 

sub execute {
	my $this = shift; use lib "$this->{lib_path}"; 
    use Cfg; use DB; 
    use Core::File;   use Data::Table;  
    use Data::Table::Excel qw( tables2xls );

    my $f_name  = 'Products';

    my $te      = [Time::HiRes::gettimeofday()];

    my $f_csv  = $cfg->{'PATH'}->{'ext'}."$f_name.csv"; 
    my $f_html = $cfg->{'PATH'}->{'ext'}."$f_name.html"; 
    my $f_xls  = $cfg->{'PATH'}->{'ext'}."$f_name.xls"; 

    ( -w $f_csv or -w $f_html or -w $f_xls or -d $cfg->{'PATH'}->{'ext'} ) or die ('file!');
    my $q = 'SELECT 
			  salemods.id   		as salemod_id, 
			  salemods.idCategory  	as category_id, 
			  salemods.idBrand     	as brand_id, 
			  category.name 		as category_name, 
			  brands.name   		as brand_name, 
			  salemods.name 		as salemod_name, 
			  ROUND(salemods.price) as price, 
			  salemods.isPublic 	as isPublic 
		 FROM salemods 
		 JOIN category ON ( category.id = salemods.idCategory ) 
		 JOIN brands   ON ( brands.id   = salemods.idBrand    )
	 ORDER BY category.idParent, category.name, brands.name, salemods.name;';

	my $t = Data::Table::fromSQL( $db, $q )
		or die ('err. exec sql query'); 

	$t->csv( 1, { file => $f_csv } ) 
		or die ('err. gen. csv');

	Core::File->replace( $f_html, $t->html() )
		or die ('err. gen. html');

	tables2xls( $f_xls, [$t], ["Product"] ) 
		or die ('err. gen. html');

	$te = Time::HiRes::tv_interval( $te ); 
	$this->log("Ok. $te sec.");
	
	return $this->{log};
}

sub new(){ my $class = shift; my $this  = {lib_pth => shift,log => '',}; return bless $this, $class; }
sub log  { my $this = shift; my $text = shift; $this->{log} .= $text."<br>"; }


1;
