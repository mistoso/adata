package Crond::SessionClean;

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
	use Core::DB;
	use Data::Dumper;
	use Cfg;
	use Core::Session;

	use Time::HiRes qw/gettimeofday tv_interval/;
	use MIME::Base64;
	use Storable qw(nfreeze thaw);
	
	my  ($sstart,$mstart)= gettimeofday();

	my $sth = $db->prepare(q/SELECT id, a_session FROM sessions/);
	$sth->execute();
	my $parsed_count = 0;
	
	my @delete = ();
	while (my ($id,$session) = $sth->fetchrow_array() ) {
		$parsed_count ++;
		my $data = thaw(decode_base64($session));
		if ( ($data->{_session_atime} + Core::Session::EXPIRE)  < time ) {
			push @delete, $id;
		}
	}
	
	my $sthc = $db->prepare_cached(q/DELETE FROM sessions WHERE id = ?/);

	foreach (@delete) {
	        $sthc->bind_param(1, $_);
	        $sthc->execute;
	        $sthc->finish;
	}

	my ($sstop,$mstop)= gettimeofday();
	
	$this->log("Parsed $parsed_count, deleted ".scalar(@delete).", by time ".($sstop - $sstart).".".($mstop - $mstart));
	$this->log("Time ".($sstop - $sstart).".".($mstop - $mstart)); 

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
