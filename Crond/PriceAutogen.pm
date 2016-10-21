package Crond::PriceAutogen;
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
    my $sth = $db->prepare('select s.id from salemods as s inner join category as c3 on c3.id = s.idCategory inner join category as c2 on c2.id = c3.idParent inner join category as c1 on c1.id = c2.idParent where c1.idParent = 0 and c3.isPublic and s.isPublic and s.priceautogen');
    $sth->execute();
    use Model::SaleMod;

    while (my ($id) = $sth->fetchrow_array){
        my $prod =  Model::SaleMod->load($id);
        $prod->priceautogen();

    }

		
	$this->log("PriceAutogen Done");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
