package Base::Mysql;

use base qw( Class::Singleton );
use DBI;
use Error;
use Base::Exception;
use Logger;


###############################################################################
sub _new_instance {
	my ( $class, $param ) = @_;
	my $this  = undef;
	
	if (!$param->{name} || !$param->{host} || !$param->{user} || !$param->{pass}) {
		throw SQL::Exception("missing to conn to the db.");
	}
	$this->{dbh} = DBI->connect("DBI:mysql:".$param->{name}.":".$param->{host}, $param->{user}, $param->{pass}, { PrintError => 1, AutoCommit => 1, RaiseError => 1 });

	$this->{select} 	= 0;
	$this->{statement} 	= 0;
	$this->{connected}	= 1;

	$log->debug("Base::MySQL: connected to the database");

	bless $this, $class;

	return $this;
}

###############################################################################
sub do($$$) {
	my ( $this, $query, $params ) = @_;
	
	my @result = ();

	##########################################
	if (ref $params eq 'ARRAY') {
	
		for (my $i = 0; $params->[$i]; $i++) {
			$params->[$i] = $this->strSQLize($params->[$i]);
			$query        =~ s/\{$i\}/$params->[$i]/g;
		}
	
	}

	$log->debug("Base::MySQL: " . $query );

	##########################################

	if ($query =~ /^[\n\s\t]*SELECT/i) 
	{

		my $sth = $this->{dbh}->prepare($query);

		if ($sth) {
			my $rv = $sth->execute;
			if ($rv) {
				while ( my $l = $sth->fetchrow_hashref ) { 	push (@result, $l);	}
				$rv = $sth->finish;
			}
		}
		$this->{select}++;
	} else {
		$this->{statement}++;
		$this->{dbh}->do($query);
	}
	$this->{data} = \@result;
	return @result;
}

###############################################################################
sub get_json {
    my $this = shift;

    if ( $this->{data} ) { 

		use JSON::Syck;

		$JSON::Syck::ImplicitUnicode = 1;
		
    	return JSON::Syck::Dump( $this->{data} ); 

    }

    return ();
}

###############################################################################
sub prepare($$$) {
	my $this   = shift;
	my $query  = shift;
	my $params = shift;
	my $result = [];

	if (ref $params eq 'ARRAY') {

		for (my $i = 0; $params->[$i]; $i++) {
			$params->[$i] = $this->strSQLize($params->[$i]);
			$query        =~ s/\{$i\}/$params->[$i]/g;
		}
	}
	$log->debug("Base::MySQL: " . $query);
	my $error_string = '';
	my $sth;
 	
 	if (!($sth = $this->{dbh}->prepare($query))) {
	   $log->error("Base::MySQL: Error while " . $query . ";". $this->{dbh}->errstr());
	}

	return $sth;

}
###############################################################################
sub strSQLize($$) {
	my $this = shift;
	my $str  = shift;

	$str =~ s/\\/\\\\/g;
	$str =~ s/\'/\\\'/g;
	$str = "\'".$str."\'";
	
	return $str;
}

###############################################################################
sub disconnect {
	my $this = shift;
	if ($this->{connected}) {
		$this->{select}     = 0;
		$this->{statement}  = 0;
		$this->{connected}	= 0;
		$this->{dbh}->disconnect;
		$log->debug("Base::MySQL: connection closed");
	}
}

###############################################################################
sub lastInsertId {
	my $this = shift;
	return $this->{dbh}->{mysql_insertid};
}

###############################################################################
sub prepare_cached {
	my $this  = shift;
	my $query = shift;
	$log->debug("Base::MySQL: " . $query);
	$this->{dbh}->prepare_cached($query);
}

###############################################################################
sub AUTOLOAD {
	my $this = shift;
	my @vars = @_;
	
	my $class = ref($this);
	$AUTOLOAD =~ s/($class)(::)//;
	$this->{dbh}->$AUTOLOAD(@vars);
}
###############################################################################
1;

