package Crond::SalerpricesDeadline;
use strict;

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

	use DB;
    use Model::SaleMod;
    
    my $sthd=$db->prepare('update salerprices,salers set salerprices.price = 0 where salers.id = idSaler and deadline > 0 and deadline < (TO_DAYS(CURDATE()) - TO_DAYS(salerprices.updated))');
    $sthd->execute() or print "deadline is not ok";
    print "deadline is ok";
    
    # autogeneraciya

    my $sthp=$db->prepare('select distinct(idSaleMod) from salerprices,salers where salers.id = idSaler and deadline > 0');
    $sthp->execute() or print "fack cant take it any more";
    
    while (my ($id) = $sthp->fetchrow_array()){
        my $salemod = Model::SaleMod->load($id);
        next unless $salemod->{id};
        $salemod->priceautogen();
        
    }
    # end	
	$this->log("updated salerprices where price deadline is gone & autogen price for this product");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
