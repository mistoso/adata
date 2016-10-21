package Core::Price;

use strict;

use Model::Currency;
use DB;

sub new {
	my $class = shift;
	bless {} => $class ;
}

sub get {
	my $self     = shift;
	my $price    = shift;

	unless ( $self->{_currency} ) {
		$self->{_currency} = Model::Currency->load('1','in_use');
		$self->{_currency} = Model::Currency->load('USD','code') unless $self->{_currency};
	}

	sprintf( "%.2f %s", ( $price * $self->{_currency}->{value} ), $self->{_currency}->{symbol} );
}

sub getByValue {
	my $self     = shift;
	my $price    = shift;
	my $currency = shift; 

	sprintf( "%.0f", ( $price * $currency ) );
}

sub getByValueUSD{
	my $self     = shift;
	my $price    = shift;
	my $currency = shift; 
	sprintf( "%.0f", ( $price / $currency ) );
}

sub getByCode {
	my $self   = shift;
	my $price  = shift;
	my $code   = shift;

	unless ( $self->{"_currency_$code"} ) {
		$self->{"_currency_$code"} = Model::Currency->load($code,'code');
		$self->{'_currency_USD'} = Model::Currency->load('USD','code') unless $self->{"_currency_$code"};
	}
	
	sprintf( "%.0f %s", ( $price * $self->{"_currency_$code"}->{value} ), $self->{"_currency_$code"}->{symbol} ); 
}


sub getByCodeVal {
	my $self   = shift;
	my $price  = shift;
	my $code   = shift;

	unless ( $self->{"_currency_$code"} ) {
		$self->{"_currency_$code"} = Model::Currency->load($code,'code');
		$self->{'_currency_USD'} = Model::Currency->load('USD','code') unless $self->{"_currency_$code"};
	}
	
	sprintf( "%.0f %s", ( $price * $self->{"_currency_$code"}->{value} ),''); 
}


sub getByCodeF {
	my $self   = shift;
	my $price  = shift;
	my $code   = shift;

	unless ( $self->{"_currency_$code"} ) {
		$self->{"_currency_$code"} = Model::Currency->load($code,'code');
		$self->{'_currency_USD'} = Model::Currency->load('USD','code') unless $self->{"_currency_$code"};
	}
	sprintf( "%.0f", ( $price * $self->{"_currency_$code"}->{value} )); 
}


sub getPublicByCode {
	my $self   = shift;
	my $price  = shift;
	my $code   = shift;
	
	my $currency = Model::Currency->load($code,'code');
	unless ($currency->{'isPublic'} eq 0){
		return $self->getByCode($price,$code);
	}
	return "";

}

sub getPublicByCodeF {
	my $self   = shift;
	my $price  = shift;
	my $code   = shift;
	
	my $currency = Model::Currency->load($code,'code');
	unless ($currency->{'isPublic'} eq 0){
		return $self->getByCodeF($price,$code);
	}
	return "";

}

1;
