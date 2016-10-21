package Crond::Galamart2Pylt;
use strict;

sub new(){	my $class = shift;	my $this  = {lib_path => shift,log      => '',};	return bless $this, $class;}

sub log {my $this = shift;my $text = shift;	$this->{log} .= $text."<br>";}

sub execute {
	my $this = shift;
	use lib "$this->{lib_path}";
#--------------------------------------------------------------------
# Your code start ehre 
#--------------------------------------------------------------------
	use DB;
	use Cfg;
	
	my $filename = $cfg->{'PATH'}->{'ext'}."new_full.csv";
	my $archiv = $cfg->{'PATH'}->{'ext'}."new_full_img";
	my $gallery =  $cfg->{'PATH'}->{'gallery'};
	unlink($filename);
	unlink($archiv.".zip");
	mkdir($archiv);
 
 	my $sth = $db->prepare("select 
		s.mpn,
		b.name as bname,
		s.name,
		s.alias,
		g.id as gid,
		REPLACE(s.Description,'','') as descr,
		REPLACE(s.DescriptionFull,'\"','\\\'') as descrf 
	from salemods s 
	inner join brands b 
		on s.idBrand = b.id 
	inner join gallery g 
		on g.name = s.alias 
	where s.mark = 1 
		and s.idImage is not null
		and LENGTH(s.Description) > 20
		and LENGTH(s.DescriptionFull) > 20
		and s.idCategory != 2378 
	 ");
	$sth->execute();
	open (MYFILE, '>>'.$filename);
	while (my $i = $sth->fetchrow_hashref()) {
		my $image = "image_".$i->{'gid'}.".png";
		#print $i->{'mpn'}." ".$i->{'alias'}." ".$image."\n";
		print MYFILE '"'.$i->{'mpn'}.'";"'.$i->{'bname'}.'";"'.$i->{'name'}.'";"'.$image.'";"'.$i->{'descr'}.'";"'.$i->{'descrf'}.'"'."\r\n";
		system("cp ".$gallery."/".$i->{'alias'}."/".$image." ".$archiv);
	}
	close (MYFILE);

	my $sth = $db->prepare("update 
		salemods s 
		set s.mark = 0 
		where s.mark = 1 
			and s.idImage is not null
			and LENGTH(s.Description) > 20
			and LENGTH(s.DescriptionFull) > 20
			and s.idCategory != 2378 ");
	$sth->execute();

	system("zip -r ".$cfg->{'PATH'}->{'ext'}."new_full_img.zip ".$cfg->{'PATH'}->{'ext'}."/new_full_img ");
	system("rm -rf ".$cfg->{'PATH'}->{'ext'}."new_full_img");



		
	$this->log("ssulka na fail csv - galamart.com.ua/ext/new_full.csv  <br> ssulka na fotoarhiv  - galamart.com.ua/ext/new_full_img.zip");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
