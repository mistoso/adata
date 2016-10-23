package Core::Guest;

use warnings; use strict;

use Core::Session;

sub new {
	my $class = shift;
	my $self = undef;
	$self->{'session'} = Core::Session->instance();
	
	bless $self,$class;
	return $self;
}

sub session {
	my $self = shift;
	return $self->{'session'};
}

sub id {
	return 0;
}
1;
