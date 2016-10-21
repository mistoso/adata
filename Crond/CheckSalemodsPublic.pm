package Crond::CheckSalemodsPublic;
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

my $ext;
my $item;
my $uext;

my $ext = $db->prepare("select c.id as cid from category c inner join category c2 ON c.id = c2.idParent where c.idParent != 0 and c.isPublic = 0 GROUP BY c.id;");
$ext->execute();
while (my $item = $ext->fetchrow_hashref){
	$uext = $db->prepare("update category set isPublic = 0 where idParent = ?");
	$uext->execute($item->{cid});
}

my $ext;
my $item;
my $uext;

my $ext = $db->prepare("select c2.id as cid from category c inner join category c2 ON c.id = c2.idParent where c.idParent != 0 and c2.isPublic = 0 GROUP BY c2.id;");
$ext->execute();
while (my $item = $ext->fetchrow_hashref){
	$uext = $db->prepare("update salemods set isPublic = 0, price = 0 where idCategory = ?");
	$uext->execute($item->{cid});
}
### misha clean salerprices
 my $ext = $db->prepare("update  salerprices as sp left outer join salemods as s on s.id = sp.idsaleMod set sp.ignored = 1 where s.id is null");
 $ext->execute();
 my $ext = $db->prepare("delete from salerprices where ignored = 1");
 $ext->execute();
 my $ext = $db->prepare("update salemods set isPublic = 0 where price = 0");
 $ext->execute();





return 1;
}

1;
