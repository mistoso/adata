package Core::Meta;
use strict;

use Core::Meta::Factory;

use Logger;

use Data::Dumper;

our $_instance;

sub instance {
        my $class = shift;
	my $force = shift;
	return $$_instance->{class}  = $class->_new_instance(@_) if $force;
	 defined $$_instance->{class} ? ($$_instance->{class}) : ($$_instance->{class} = $class->_new_instance(@_));

}

sub _new_instance {
	my $class = shift;
    my $this  = ();
    $this  = bless { }, $class;
	$this->{request} = shift;
	$this->{package} = shift || 'url';
	$log->debug('Core::Meta: request = '.$this->{request}.' and package = '.$this->{package});
	return $this;
}

sub change {
	my $this = shift;
	$this->{request} = shift;
	$this->{package} = shift || 'url'; 
	$log->debug('Core::Meta: CHANGE request = '.$this->{request}.' and package = '.$this->{package});

}

sub init {
	my $this = shift;
	unless ($this->{class}) {
		$this->{class} = Core::Meta::Factory->init($this->{package},$this->{request});
	}
	return $this->{class};
}

sub title() {
	my $this = shift;
	my $class = $this->init();
	return $class->getTitle();
}


sub description() {
	my $this = shift;
	my $class = $this->init();
	return $class->getDescription();
}

sub keywords () {
	my $this = shift;
	my $class = $this->init();
	return $class->getKeywords();
}

sub f_block_left () {
    my $this = shift;
    my $class = $this->init();
    return $class->getF_block_left();
}

sub s_block () {
    my $this = shift;
    my $class = $this->init();
    return $class->getS_block();
}

1;

