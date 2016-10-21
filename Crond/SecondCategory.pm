package Crond::SecondCategory;

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

    my $stt = Base::StTemplate->instance($cfg->{'stt'});
    $arg{lib} = Core->new();
        
    $stt->SetAndGenerate("frontoffice/static/common/footer_top.html","frontoffice/static/common/footer_top.html",\%arg);
    

	$this->log("Generate footer menu done");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
