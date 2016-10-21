package Core::Winkelwagen::Product;

use Model::SaleMod;
use Core::Session;
use Data::Dumper;
use DB;
use Logger;

sub getAll() {
	my $this = shift;
	my @buf;
	my $s = Core::Session->instance();

	my $products = $s->get('winkelwagen');
	foreach my $key ( keys %{$products}) {
		push (@buf,{
				product => Model::SaleMod->load($key,'id'),
				count   => $products->{$key}, 
		});
	}
	return \@buf;
}

sub getAllSumm() {
	my $this = shift;
	my $summ = 0;
	my $s = Core::Session->instance();

	my $products = $s->get('winkelwagen');
	foreach my $key ( keys %{$products}) {
		if ($key eq ''){next;}
		my $sth = $db->prepare("select price from salemods where id = '".$key."'");
		$sth->execute();
		my $price = $sth->fetchrow_array;
		$summ  += ($price * $products->{$key});
	}
	return $summ;
}

sub getCount() {
	my $this = shift;
	my $count = 0;
	my $s = Core::Session->instance();

	my $products = $s->get('winkelwagen');
	foreach my $key ( keys %{$products}) {
		if ($key eq ''){next;}
		$count += $products->{$key};
	}
	return $count;
}

sub change(){
	my $this   = shift;
	my $id     = shift;
	my $amount = shift;

	if ($id =~ /^\d+$/ and $amount =~ /^\d+$/) {
		my $s = Core::Session->instance();
		my $products = $s->get('winkelwagen');

		$products->{$id} = $amount;
		$s->set('winkelwagen' => $products);
		$s->save();
	}

}

sub add() {
	my $this  = shift;
	my $id    = shift;
	my $value = shift || 1;

	unless ($value =~ /^\d+$/ ) {
		$value = 1;
	}

	my $s = Core::Session->instance();
	my $product = Model::SaleMod->load($id,'id');	
	
	if ($product->{price}) {
		my $product = $s->get('winkelwagen');
		$product->{$id} = $value ;

		$s->set('winkelwagen' => $product);
		$s->save();

		return 1;
	}
	return 0;
}

sub deleteAll() {
	my $this = shift;
	my $id   = shift;

    my $s = Core::Session->instance();
    my $products = $s->get('winkelwagen');

    $s->set('winkelwagen' => '');
    $s->save();
}

sub delete() {
	my $this = shift;
	my $id   = shift;
    warn "$id _____________________________"; 

	if ($id =~ /\d+/){
		my $s = Core::Session->instance();
		my $products = $s->get('winkelwagen');

        warn ">>>>>>>>>>>>>>>>".Dumper($products);
		delete $products->{$id};
        warn "<<<<<<<<<<<<<<<<<".Dumper($products);
		$s->set('winkelwagen' => $products);
		$s->save();
	}
}

sub dumper() {
	my $this = shift;
	
	my $s = Core::Session->instance();
	return Dumper($s->get('winkelwagen'));
}
1;
