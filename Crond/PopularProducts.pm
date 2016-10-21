package Crond::PopularProducts;

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
    use Data::Dumper;
    use Model::Category; 
    use Core::Price;
    use Banner;

    my $stt = Base::StTemplate->instance($cfg->{'stt'});
    $arg{lib} = Core->new();
    $arg{banner} = Banner->new();
    $arg{price}  = Core::Price->new();

    $stt->SetAndGenerate("frontoffice/static/common/front_center.html","frontoffice/static/common/front_center.html",\%arg);
    

	$this->log("Generate popular products done");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
