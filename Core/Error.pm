package Core::Error;
use strict;

use Data::Dumper;
use Core::Session;

sub new(){
    my $class = shift;

    bless {},$class;
}

sub get {
	my $this = shift;
	my $key  = shift;

	my $s = Core::Session->instance();
	if (my $error = $s->get('_errors')) {
		return $error->{$key};
	}
}

sub set {
	my $this = shift;
	my $key  = shift;
	
	my $s = Core::Session->instance();
	my $error = $s->get('_errors');
	$error->{$key}     = 1;
	
	$s->set('_errors' => $error);
	$s->set('_was_error' => 1);
	$s->save();
}

sub error {
	my $s = Core::Session->instance();
	return $s->get('_was_error');
}

sub clean {
	my $s = Core::Session->instance();
	$s->remove('_errors');
	$s->remove('_was_error');
	$s->save();
}

sub dumper {
	my $s = Core::Session->instance();
	return Dumper($s->get('_errors'));
}

1;
