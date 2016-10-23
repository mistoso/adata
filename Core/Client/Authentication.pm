package Core::Client::Authentication;

use strict;

use Data::Dumper;
use Core::Session;

use Logger;
use Mail::RFC822::Address qw(valid) ;

use Core::User;

sub login {
	my $this   = shift;
	my $login  = shift;
	my $passwd = shift;

	$login  =~ s/^\s*//g;
	$login  =~ s/\s*$//g;

	$passwd =~ s/^\s*//g;
	$passwd =~ s/\s*$//g;
	my $error = 0;

	if (valid($login)) {

		my $client = Model::Client->load($login,'email');

		if ($client) {

			if ($client->{'password'} eq $passwd) {

				my $s = Core::Session->instance();
				$s->set( login_id => $client->{id} );
				$s->save(); 
				return 1;

			}

		}
	}
	return 0;
}

sub logout {
	my $this  = shift;
	my $s = Core::Session->instance();
	$s->remove('login_id');
	$s->save();
}

sub passwordCheck {
	my $this   = shift;
	my $passwd = shift;
	my $client = Core::User->current();
	return unless $client;
	return 1 if $client->{'password'} eq $passwd ;
	return 0;
}

1;
