package Crond::GetLatestProduct;

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

	use Core;
	use DB;
	use Data::Dumper;
	use Cfg;
	use Core::Price;
	use Model::SaleMod;
        use Base::StTemplate;
	
	my $sth = $db->prepare(q/INSERT INTO salemods_order_inflow(id) SELECT s.id FROM salemods s LEFT JOIN salemods_order_inflow soi USING(id) WHERE soi.id IS NULL/);
    	$sth->execute();
	
	#my $sth = $db->prepare(q/ select id from salemods where price > 0 and price != 9999 and isPublic = 1 order by id desc LIMIT 12 /);
	
	my $sth = $db->prepare(q/ SELECT so.id as id FROM salemods_order_inflow so INNER JOIN salemods sm ON sm.id = so.id where sm.isPublic = 1 AND sm.price > 0 ORDER BY sm.id desc LIMIT 12 /);
	$sth->execute();

	my @buf = ();
	while ( my ($id) = $sth->fetchrow_array()) {
		push (@buf, Model::SaleMod->load($id));
	}

	$this->log("Hm... Products buffer is empty.. I will generate empty file :(") unless scalar @buf > 0;
        my $stt = Base::StTemplate->instance($cfg->{stt});
        $arg{lib}      = Core->new();
	$arg{price}    = Core::Price->new();
	$arg{products} = \@buf;
	
	# TT search files first in STT output path X) 

        $stt->SetAndGenerate("frontoffice/static/blocks/incoming.html","frontoffice/static/blocks/incoming.html",\%arg);
	$this->log("File generated successfully");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
