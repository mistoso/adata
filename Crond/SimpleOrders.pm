package Crond::SimpleOrders;
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
     use Core;
     use Core::DB;
     use Core::Gallery;
     my $xsth = $db->prepare("truncate table simple_orders;");
     $xsth->execute();
     my $sql = "INSERT INTO simple_orders(idMod, idModCount, idCat,idBrand,idParent, modName, brandName, catName, modAlias, catAlias, ParentCatAlias, brandAlias, smprice, smidImage)
		     SELECT op.idMod,
		    	    count(op.idMod),
		    	    c.id,
		    	    b.id,
		    	    c.idParent,
		    	    sm.name,
		    	    b.name,
		    	    c.name,
		    	    sm.alias,
		    	    c.alias,
		    	    c2.alias,
		    	    b.alias,
		    	    sm.price,
			    g.id
                       FROM orderspositions as op
                 INNER JOIN salemods as sm ON op.idMod = sm.id
                 INNER JOIN category as c ON sm.idCategory = c.id
                 INNER JOIN category as c2 ON c.idParent = c2.id
                 INNER JOIN brands as b ON sm.idBrand = b.id 
                 INNER JOIN gallery as g ON sm.GalleryName = g.name
                      WHERE op.soldDate BETWEEN DATE_SUB(now(), INTERVAL 91 DAY) and DATE(NOW())
                        AND sm.price > 0 
                        AND sm.price != 9999 
                        AND sm.deleted != 1
                        AND sm.isPublic = 1
                        AND op.state = 'sold'
                        AND op.deleted != 1
                        AND c.idParent > 0
                        AND g.gOrder = 1
                   GROUP BY op.idMod
                   ORDER BY count(op.idMod) DESC";
    my $sth = $db->prepare("$sql");
    $sth->execute();

    my $sth = $db->prepare("select idMod, smidImage from simple_orders");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	my $model  = Core::Gallery::Image->load($item->{smidImage});
	warn "\n\n $item->{idMod} ".$model->path('75','75','jpg');
    }
    return 1;
}

1;
