package Crond::Catalog;

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
	use DB;
	use Base::StTemplate;
	use Model::Catalog;
	#--------------------------------------------------------------------
	# Your code start ehre 
	#--------------------------------------------------------------------
	my $sth = $db->prepare('select id as id from catalog where isPublic = 1 order by name');
	$sth->execute();
	while (my $item = $sth->fetchrow_hashref){
	    my $catalog = Model::Catalog->load($item->{id});

	    if( $catalog->{type} eq 'xls'){
		$catalog->catalog_drow_xls();
		return OK;
	    }

	    if( $catalog->{type} eq 'csv'){
		my $put = $catalog->{file};
		my $stt = Base::StTemplate->instance($cfg->{'stt_catalog'});
		my $arg = ();
		$catalog->catalog_drow_csv();
		$arg->{rows} = $catalog->catalog_xls_csv_data();
        	$arg->{lib} = Core->new();
		$stt->SetAndGenerate('backoffice/templates/catalog/cat_temp/'.$catalog->{id}.'_'.$catalog->{type}.'.html',$put, $arg);
	    }
	    if( $catalog->{type} ne 'xls' && $catalog->{type} ne 'csv' && $catalog->{type} ne ''){
		#$catalog->catalog_get_xml_prod();
		my $put = $catalog->{file};
		my $stt = Base::StTemplate->instance($cfg->{'stt_catalog'});
        	my $arg = ();
		$arg->{cat_list} = $catalog->catalog_get_xml_cat();
		$arg->{prod_list} = $catalog->catalog_get_xml_prod();
        	$arg->{lib} = Core->new();
    		$stt->SetAndGenerate('backoffice/templates/catalog/cat_temp/'.$catalog->{type}.'.html',$put, $arg);
	    }
	}
    $this->log("All activ catalog - done");
    return $this->{log};
}

1;
