package Crond::XmlSitemap;
use Core;
use Cfg;
use Core::DB;
use Base::StTemplate;
use POSIX qw(ceil floor);

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
    &xml_sitemap();

    $this->log("Generate frontpage xml_sitemap - sitemap - done");
#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
    return $this->{log};
}

sub xml_sitemap(){
    my $site_url = $cfg->{'temp'}->{'host'};
    my $changefreq;  #always  #hourly  #daily  #weekly  #monthly  #yearly  #never
    my $priority;    #0.5 - 1.0
    my $lastmod;     #2005-01-01
    my $file;
    my $i = 0;
    my $count;
    &xml_sitemap_prepare();
    #######
    ############################ salemods ###############################################
    my $sth = $db->prepare("SELECT distinct(sm.alias) as loc
			      FROM salemods sm INNER JOIN category c ON c.id = sm.idCategory 
		        INNER JOIN category c2 ON c.idParent = c2.id 
		        INNER JOIN brands b ON sm.idBrand = b.id 
		             WHERE sm.isPublic = 1 
		               AND sm.deleted != 1 
		               AND sm.idCategory > 0 
		               AND b.deleted != 1 
			  ORDER BY sm.id;");
    $sth->execute();
    $changefreq = 'daily';
    $priority = '0.8';
    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0;
	$changefreq = 'daily';$priority = '1.0';
	$loc = $item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, '1.0');
    }

    #######
    ############################ cat first level ###############################################
    my $sth = $db->prepare("SELECT concat(c2.alias,'.html') as loc
			      FROM category c1 INNER JOIN category c2 ON c2.idParent = c1.id 
			     WHERE c1.idParent = 0 
			       AND c1.isPublic 
			       AND c2.isPublic;");
    $sth->execute();
    $changefreq = 'daily';
    $priority = '1.0';
    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0;
	$loc = $item->{loc};
	&xml_sitemap_insert_loc($loc, $changefreq, $priority);
    }

    #######
    ############################ cat sec level ###############################################
    my $sth = $db->prepare("SELECT concat(c2.alias,'/',c3.alias) as loc, 
				   count(distinct(sm.id)) as pc, 
				   ceil(count(distinct(sm.id))/124) p36
			      FROM category as c3 LEFT JOIN category as c2 on c3.idParent = c2.id 
			INNER JOIN salemods sm ON c3.id = sm.idCategory 
			INNER JOIN brands b ON sm.idBrand = b.id 
			    WHERE c3.deleted != 1  
			      AND c2.deleted != 1 
			      AND sm.deleted != 1 
			      AND c2.idParent 
			 GROUP BY c3.id ORDER BY c2.name, c3.name");
    $sth->execute();
    $changefreq = 'daily';
    $priority = '1.0';
    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0;
	$loc = $item->{loc}.".html";
	$count = 0; for ($count = 1; $count <= $item->{p124};  $count++)  { $loc = $item->{loc}."/".$count."_124.html"; &xml_sitemap_insert_loc($loc, $changefreq, $priority); }
    }


    #######
    ############################ cat brands ###############################################
    my $sth = $db->prepare("SELECT concat(c2.alias,'/',c.alias,'/', b.alias) as loc, 
				   ceil((count(sm.id)/124)) as  p124
			      FROM salemods sm INNER JOIN category c ON c.id = sm.idCategory 
			INNER JOIN category c2 ON c.idParent = c2.id 
			INNER JOIN brands b ON sm.idBrand = b.id 
			     WHERE sm.deleted != 1 
			       AND sm.idCategory > 0 
			       AND b.deleted != 1 
			  GROUP BY sm.idCategory, sm.idBrand 
			  ORDER BY sm.idCategory;");
    $sth->execute();
    $changefreq = 'daily';
    $priority = '1.0';
    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0;
	$loc = $item->{loc}.".html";
	&xml_sitemap_insert_loc($loc, $changefreq, $priority);
	$count = 0; for ($count = 1; $count <= $item->{p124};  $count++)  { $loc = $item->{loc}."/".$count."_124.html"; &xml_sitemap_insert_loc($loc, $changefreq, $priority); }
    }
    #######
    ############################ brands ###############################################
    my $sth = $db->prepare("SELECT concat('sitemap/brand/',brands.alias,'.html') as loc
			      FROM brands INNER JOIN salemods ON salemods.idBrand = brands.id 
			INNER JOIN category ON salemods.idCategory = category.id 
			       AND brands.deleted != 1 
			       AND salemods.deleted != 1 
			       AND category.deleted != 1 
			  GROUP BY brands.id 
			  ORDER BY brands.alias;");
    $sth->execute();
    $changefreq = 'daily';
    $priority = '1.0';
    while (my $item = $sth->fetchrow_hashref){
	&xml_sitemap_insert_loc($item->{loc}, $changefreq, $priority);
    }

    &xml_sitemap_clean_old();
    &xml_sitemap_create_xml();
}

sub xml_sitemap_insert_loc(){
    my ($loc ,$changefreq, $priority) = @_;
    my $i = 0;

    $loc =~ s/'//g;
    $loc =~ s/ //g;
    $loc =~ s/\&//g;
    $loc =~ s/\<//g;
    $loc =~ s/\>//g;	
    $loc =~ s/\n//g;	
    $loc =~ s/"//g;
    $loc =~ s/"//g;
    $loc =~ s/'//g;
    $loc =~ s/\&//g;
    $loc =~ s/\<//g;
    $loc =~ s/\>//g;	
    $loc =~ s/\n//g;	

    my $isth = $db->prepare("REPLACE xml_sitemap set loc = ?, changefreq = ?, priority = ?, deleted = ?");
    $isth->execute( $loc, $changefreq, $priority, '0');
}

sub xml_sitemap_prepare(){
    my $sth = $db->prepare("update xml_sitemap set deleted = 1;");
    $sth->execute();
}

sub xml_sitemap_clean_old(){
    my $sth = $db->prepare("delete from xml_sitemap where deleted = 1;");
    $sth->execute();
}

sub xml_sitemap_create_xml(){
    my ($offset,$limit) = (0,40000);

    my $csth = $db->prepare("select count(*) from xml_sitemap");
    $csth->execute();
    my ($count) = $csth->fetchrow_array();

	my $command = 'rm -f '.$cfg->{'stt_sitemap'}->{OUTPUT_PATH}.'/sitemap*.xml';
	system($command);

	$command = 'rm -f '.$cfg->{'stt_sitemap'}->{OUTPUT_PATH}.'/sitemap_light*.txt';
	system($command);


    foreach $file_count (@{[1..ceil($count / $limit)]}) {

        print "Got  $offset,$limit  (file $file_count) \n";

        my @buff = ();
        my $sth = $db->prepare("select loc, changefreq, priority from xml_sitemap limit $offset,$limit ");
        $sth->execute();


        while (my $item = $sth->fetchrow_hashref()) {
            next unless ($item->{loc} =~ /^(\_|\w|\d|\-|\+|\(|\)|\,|\/|\.)+$/i);
            push (@buff,$item);
        }

        my $stt = Base::StTemplate->instance($cfg->{'stt_sitemap'});

        $stt->SetAndGenerate("backoffice/templates/tools/sitemap.html","sitemap$file_count.xml",{buf => \@buff, config => $cfg->{'temp'} });

        my $command = 'gzip -f '.$cfg->{'stt_sitemap'}->{OUTPUT_PATH}."/sitemap$file_count.xml";
        system($command);


        @buff = ();
        my $sth = $db->prepare("select loc, changefreq, priority from xml_sitemap limit $offset,$limit ");
        $sth->execute();


        while (my $item = $sth->fetchrow_hashref()) {
            next unless ($item->{loc} =~ /^.+(\.html)+$/i);
            push (@buff,$item);
        }


        $stt->SetAndGenerate("backoffice/templates/tools/sitemap_light.html","sitemap_light_$file_count.txt",{buf => \@buff, config => $cfg->{'temp'} });





        $offset += $limit;
    }


}




1;
