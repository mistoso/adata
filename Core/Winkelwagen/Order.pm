package Core::Winkelwagen::Order;

use Model::SaleMod;
use Core::Session;
use Data::Dumper;
use Core::DB;
use Logger;

sub storeOrder () {
	my $this = shift;
	my $user = shift;
	my $payment = shift;
	my $delivery = shift;
	
	my $order = Model::NewOrder->new();

	$order->{'state'} = 'new';
	$order->{'currencyValue'} = $payment->currency->{'value'};
	$order->{'idPayment'} = $payment->{'id'};
	$order->{'idCurrency'} = $payment->currency->{'id'};
	$order->{'idClient'} = $user->{'id'};
	$order->{'idClientF'} = $user->{'id'};
    
    if ($delivery->{id} eq '1') {
	    $order->{'deliveryAddress'} = $delivery->{comment};
    }
    else {
	    $order->{'deliveryAddress'} = $delivery->straddr();
    }
	$order->{'cName'} = $user->fullName();
	$order->{'cEmail'} = $user->{'email'};

    if ($delivery->{id} eq '1') {
	    $order->{'cContacts'} = $user->fullphone()." ".$delivery->{comment};
    }
    else {
	    $order->{'cContacts'} = $user->fullphone()." ".$delivery->straddr();
    }

	$order->{'created'} = 'NOW()';
	
	$order->save();
	
	return $order->{'id'};
}

sub storeOrderPosition(){
	my $this = shift;
	my $idOrder = shift;
	my $idMod = shift;
	my $count = shift;

	my $product = Model::SaleMod->load($idMod);
	my $position = Model::NewOrder::Position->new();

	$position->{'state'} = 'new';
	$position->{'idMod'} = $product->{'id'};
	$position->{'idOrder'} = $idOrder;
	$position->{'price'} = $product->{'price'};
	$position->{'count'} = $count;

	$position->save();

	return OK;

}

	       

1;
