package Crond::ManCatalog;

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
	use Cfg;
	use Core::DB;
	use Base::StTemplate;
	use Model::Catalog;
	#--------------------------------------------------------------------
	# Your code start ehre 
	#--------------------------------------------------------------------
	my $msth = $db->prepare("select id from catalog_man;");
	$msth->execute();
	while (my $mitem = $msth->fetchrow_hashref){
	    my $sth = $db->prepare('select id as id from catalog where id = ? and isPublic = 1 and deleted != 1 order by name');
	    $sth->execute($mitem->{id});
	    while (my $item = $sth->fetchrow_hashref){
		my $catalog = Model::Catalog->load($item->{id});
		if( $catalog->{type} eq 'xls' ){
		    $catalog->catalog_drow_xls();
		}
		if( $catalog->{type} ne 'xls' && $catalog->{type} ne 'csv' && $catalog->{type} ne ''){
		    #$catalog->catalog_get_xml_prod();
		    my $put = $catalog->{file};
		    my $stt = Base::StTemplate->instance($cfg->{'stt_catalog'});
    		    my $arg = ();
		    $arg->{cat_list} = $catalog->catalog_get_xml_cat();
		    $arg->{prod_list} = $catalog->catalog_get_xml_prod();
    		    $stt->SetAndGenerate('backoffice/templates/catalog/cat_temp/'.$catalog->{type}.'.html',$put, $arg);
		}
	    }
	}
}

1;
