package Crond::TopBrand;

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
#--------------------------------------------------------------------
# Your code start ehre 
#--------------------------------------------------------------------

    use Core;
    use Cfg;
    use DB;
    use Base::StTemplate;
    
    $arg{lib} = Core->new();
    my $stt = Base::StTemplate->instance($cfg->{'stt'});

    $stt->SetAndGenerate("frontoffice/static/banners/hits_side_1.html","frontoffice/static/banners/hits_side_1.html",\%arg);
		
	$this->log("Generate frontpage topBrand - banners/hits_side_1.html  - done");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
