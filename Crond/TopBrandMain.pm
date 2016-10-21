package Crond::TopBrandMain;

sub new(){ my $class = shift; my $this  = { lib_path => shift, log => '' }; return bless $this, $class; }
sub log  { my $this = shift;   my $text = shift; $this->{log} .= $text."<br>"; }

sub execute {
	my $this = shift; use lib "$this->{lib_path}";

	# Your code start ehre 
        use Core;
	use Cfg;
	use DB;

	$arg{lib} = Core->new();



	# Your log mess
	$this->log("Generate frontpage top_brand_main_frame - banners/item_of_day_2.html  - done");
	# Your code end
	return $this->{log};
}

1;
