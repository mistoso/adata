package Crond::Example;

use strict;

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

	use Core::DB;
	
	# ... ... ... ...
	#do something
	# ... ... ... ...
		
	$this->log("Hello world");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
