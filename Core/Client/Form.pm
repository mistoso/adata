package Core::Client::Form;

use strict;

use locale;
use POSIX qw(locale_h);
setlocale(LC_CTYPE,"ru_RU.UTF8");

use Cfg;
use Core::Error;
use Logger;
use Clean;
use Data::Dumper;

sub checkRequiredQuickOrderFields {
	my $this = shift;
	my $args = shift;
	Core::Client::Form->checkRequiredFields($args,'quick_order');	
}

sub checkRequiredOwnFields {
	my $this = shift;
	my $args = shift;
	Core::Client::Form->checkRequiredFields($args,'own');	
}

sub checkRequiredAddressFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->checkRequiredFields($args,'address');
}

sub checkRequiredPhoneFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->checkRequiredFields($args,'phone');
}

sub getQuickOrderFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->getFields($args,'quick_order');
}

sub getOwnFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->getFields($args,'own');
}

sub getAddressFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->getFields($args,'address');
}

sub getPhoneFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->getFields($args,'phone');
}

sub checkRequiredRestorePassFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->checkRequiredFields($args,'restore_pass');
}

sub getRestorePassFields {
	my $this = shift;
	my $args = shift;

	Core::Client::Form->getFields($args,'restore_pass');
}

sub getContactsFields {
	my $this = shift;
	my $args = shift;
	Core::Client::Form->getFields($args,'contacts');
}

sub checkRequiredContactFields {
	my $this = shift;
	my $args = shift;
	Core::Client::Form->checkRequiredFields($args,'contacts');
}

sub checkRequiredFields {
	my $this = shift;
	my $args = shift;
	my $what = shift;

	foreach my $key (keys %{$cfg->{'clients'}->{'required'}->{$what}}) {
		if (not ($args->{$key} =~ /$cfg->{'clients'}->{'required'}->{$what}->{$key}/)) {
			$log->info("Client::Form: Got error then check required $what field $key '".$args->{$key}."'");
			print $key;
			Core::Error->set($key);
		}
	}
}

sub getFields {
	my $this = shift;
	my $args = shift;
	my $what = shift;
	my $tmp  = ();
	foreach my $key (@{$cfg->{'clients'}->{'may_save'}->{$what}}) {
		$tmp->{$key} = $args->{$key};	
	}
	return $tmp;
}


sub checkIsEmailUnique {
	my $this   = shift;
	my $email  = shift;
	my $client = Model::Client->load($email,'email');
	if ($client and $client->{id} =~ /^\d+$/ ) {
		$log->info("Client::Form: Error - Email is not unique ".$email);
		Core::Error->set('unique_email');
	}
}

sub passwordCheck {
	my $this     = shift;
	my $password = shift;



}



1;
