package Crond::PUTableClear;
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
	use Core;
	use Core::DB;

	my $sth = $db->prepare("show tables like 'pu_%'");
	$sth->execute();

	$this->log('get tables');
	my $count;
	while (my $table_name = $sth->fetchrow_array()) {
		my $saler = $db->prepare("drop table $table_name");
		$saler->execute();
		$count++;
	}

	$this->log("drop $count tables");
        return $this->{log};
}

1;
