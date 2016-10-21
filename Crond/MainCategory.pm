package Crond::MainCategory;

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
	use Core::DB;
	use Base::StTemplate;
	use Data::Dumper;
	use Model::Category;

    my $stt = Base::StTemplate->instance($cfg->{'stt'});
    $arg{lib} = Core->new();
        
    $stt->SetAndGenerate("frontoffice/static/common/menu.html","frontoffice/static/common/menu.html",\%arg);
    

	$this->log("Generate header menu done");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
