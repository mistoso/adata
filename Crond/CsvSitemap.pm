package Crond::CsvSitemap;
    use warnings;
    use Core;
    use Cfg;
    use DB;
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
    my $sth = $db->prepare("SELECT 
                    distinct(sm.alias) as loc, 
		    sm.name as name,
                    c.name c3name, 
                    c2.name c2name, 
                    c3.name c1name
			       FROM salemods sm INNER JOIN category c ON c.id = sm.idCategory 
			 INNER JOIN category c2 ON c.idParent = c2.id 
			 INNER JOIN brands b ON sm.idBrand = b.id 
			 INNER JOIN category c3 ON c2.idParent = c3.id
			      WHERE sm.isPublic = 1 
			        AND sm.deleted != 1 
			        AND sm.idCategory > 0 
			        AND b.deleted != 1 ORDER BY sm.id;");
    $sth->execute();

    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0; 
	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; '.$item->{name}; $priority = 'products.csv';
	$loc = $item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);

	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; '.$item->{name}.' Р”РёРЅР°РјРёРєР° РёР·РјРµРЅРµРЅРёСЏ С†РµРЅ '; $priority = 'ext_products.csv';
	$loc = "cenu/".$item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);

	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; Р’РёРґРµРѕ '.$item->{name}; $priority = 'ext_products.csv';
	$loc = "video/".$item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);
#
	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; '.$item->{name}.' С‡Р°СЃС‚РЅС‹Рµ РѕР±СЊСЏРІР»РµРЅРёСЏ Рѕ РїСЂРѕРґР°Р¶Рµ '; $priority = 'ext_products.csv';
	$loc = "prodam/".$item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);
#
	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; '.$item->{name}.' РґРѕСЃС‚Р°РІРєР° РїРѕ РљРёРµРІСѓ Рё РЈРєСЂР°РёРЅРµ '; $priority = 'ext_products.csv';
	$loc = "dostav/".$item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);
#
	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; '.$item->{name}.' - РѕС‚Р·С‹РІС‹ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№. '; $priority = 'ext_products.csv';
	$loc = "otziv/".$item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);
#
	$changefreq = $item->{c1name}.' \ '.$item->{c2name}.' \ '.$item->{c3name}.' ; РђРєСЃРµСЃСЃСѓР°СЂС‹  РґР»СЏ '.$item->{name}; $priority = 'ext_products.csv';
	$loc = "acces/".$item->{loc}.".htm"; &xml_sitemap_insert_loc($loc, $changefreq, $priority);
    }

    #######
    ############################ cat first level ###############################################
    my $sth = $db->prepare("SELECT concat(c2.alias,'.html') as loc,
                                   c1.name as name
			      FROM category c1 INNER JOIN category c2 ON c2.idParent = c1.id 
			     WHERE c1.idParent = 0 
			       AND c1.isPublic 
			       AND c2.isPublic;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0;
	$changefreq = $item->{name};
	$priority = 'category.csv';
	$loc = $item->{loc};
	&xml_sitemap_insert_loc($loc, $changefreq, $priority);
    }
    
    #######
    ############################ cat sec level ###############################################
    my $sth = $db->prepare("SELECT concat(c2.alias,'/',c3.alias) as loc, 
				   count(distinct(sm.id)) as pc, 
				   ceil(count(distinct(sm.id))/10) as p10, 
				   ceil(count(distinct(sm.id))/12) p12, 
				   ceil(count(distinct(sm.id))/40) p40, 
				   ceil(count(distinct(sm.id))/100) p100,
				   c3.name as name
			      FROM category as c3 LEFT JOIN category as c2 on c3.idParent = c2.id 
			INNER JOIN salemods sm ON c3.id = sm.idCategory 
			INNER JOIN brands b ON sm.idBrand = b.id 
			    WHERE c3.isPublic = 1 
			      AND c2.isPublic = 1 
			      AND sm.isPublic = 1 
			      AND c3.deleted != 1  
			      AND c2.deleted != 1 
			      AND sm.deleted != 1 
			      AND c2.idParent 
			 GROUP BY c3.id ORDER BY c2.name, c3.name");
    $sth->execute();
    $changefreq = 'daily';
    $priority = '1.0';
    while (my $item = $sth->fetchrow_hashref){
	my $loc = 0;
	$changefreq = $item->{name};
	$priority = 'category.csv';
	$loc = $item->{loc}.".html";
	&xml_sitemap_insert_loc($loc, $changefreq, $priority);
    }

    
    
    #######
    ############################ cat brands ###############################################
    my $sth = $db->prepare("SELECT concat(c2.alias,'/',c.alias,'/', b.alias) as loc, 
                                    c.name as cname,
                                    b.name as name,
                                    b.rusName as rname
				  FROM salemods sm INNER JOIN category c ON c.id = sm.idCategory 
			INNER JOIN category c2 ON c.idParent = c2.id 
			INNER JOIN brands b ON sm.idBrand = b.id 
			     WHERE sm.isPublic = 1 
			       AND sm.deleted != 1 
			       AND sm.idCategory > 0 
			       AND b.deleted != 1 
			  GROUP BY sm.idCategory, sm.idBrand 
			  ORDER BY sm.idCategory;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	    my $loc = 0;
	    $changefreq = $item->{cname}." ".$item->{name}." ".$item->{rname};
	    $priority = 'category_brands.csv';
	    $loc = $item->{loc}.".html";
	    &xml_sitemap_insert_loc($loc, $changefreq, $priority);
    }
    #######
    ############################ brands ###############################################
    my $sth = $db->prepare("SELECT concat('brands/',brands.alias,'.shtml') as loc,
                                   brands.alias name,
                                   brands.rusName as rname
			      FROM brands INNER JOIN salemods ON salemods.idBrand = brands.id 
			INNER JOIN category ON salemods.idCategory = category.id 
			       AND brands.deleted != 1 
			       AND salemods.deleted != 1 
			       AND salemods.isPublic = 1 
			       AND category.deleted != 1 
			       AND category.isPublic = 1 
			       AND salemods.price > 0 
			  GROUP BY brands.id 
			  ORDER BY brands.alias;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	$changefreq = 'РљР°С‚Р°Р»РѕРі С‚РѕРІР°СЂРѕРІ '.$item->{name}.' '.$item->{rname};
	$priority = 'brands.csv';
	&xml_sitemap_insert_loc($item->{loc}, $changefreq, $priority);
    }

    #######
    ############################ apr_types ###############################################
    my $sth = $db->prepare("select concat('info/',alias,'.htm') as loc, name from apr_types where isPublic = 1;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	$changefreq = $item->{name};
	$priority = 'info.csv';
	&xml_sitemap_insert_loc($item->{loc}, $changefreq, $priority);
    }


    #######
    ############################ apr sections ###############################################
    my $sth = $db->prepare("select concat('info/',apt.alias,'/',aps.alias, '.htm') as loc,
                                   aps.name as name
			      FROM apr_types apt INNER JOIN apr_sections aps ON apt.id = aps.type 
			     WHERE apt.isPublic = 1 
			       AND aps.isPublic = 1 
			  GROUP BY aps.alias;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){

        $changefreq = $item->{name};
	$priority = 'info.csv';
	&xml_sitemap_insert_loc($item->{loc}, $changefreq, $priority);
    }

    #######
    ############################ apr pages  ###############################################
    my $sth = $db->prepare("select concat('info/',aprp.alias,'.html') as loc,
                                   aprp.name as name
			      FROM apr_types apt INNER JOIN apr_sections aps ON apt.id = aps.type 
		        INNER JOIN apr_pages aprp ON aps.id = aprp.idCategory 
		             WHERE apt.isPublic = 1 
		               AND aps.isPublic = 1 
		               AND aprp.isPublic = 1 
		               AND aprp.deleted != 1 
		          GROUP BY aprp.id;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
	$changefreq = $item->{name};
	$priority = 'info.csv';

	&xml_sitemap_insert_loc($item->{loc}, $changefreq, $priority);
    }

    #######
#    ############################ stock pages  ###############################################
#    my $sth = $db->prepare("select concat('rasprodaja/',distinct(category.alias),'.htm') as loc,
#                                    category.name as cname
#			      from stock, salemods, category 
#			     where isNeedToSell =1 
#			       and stock.deleted != 1 
#			       and idMod = salemods.id 
#			       and category.id = idCategory;");
#    $sth->execute();
#    while (my $item = $sth->fetchrow_hashref){
#	$changefreq = 'Р Р°СЃСЃРїСЂРѕРґР°Р¶Р° '.$item->{cname};
#	$priority = 'stock.csv';
#
#	&xml_sitemap_insert_loc($item->{loc}, $changefreq, $priority);
#    }

#    &xml_sitemap_clean_old();

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

    my $isth = $db->prepare("REPLACE csv_sitemap set loc = ?, name = ?, file_name = ?");
    $isth->execute( $loc, $changefreq, $priority);
}

sub xml_sitemap_prepare(){
    my $sth = $db->prepare("delete from csv_sitemap;");
    $sth->execute();
}

sub xml_sitemap_clean_old(){
#    my $sth = $db->prepare("delete from csv_sitemap where deleted = 1;");
#    $sth->execute();
}

sub xml_sitemap_create_xml(){
    my @files = ('products.csv','ext_products.csv','category.csv','category_brands.csv','brands.csv','info.csv'); 
    foreach my $arg (@files){
    	    my $sth = $db->prepare("select loc, name, file_name from csv_sitemap where file_name = ?");
	    $sth->execute($arg);
	    $cat = "$cfg->{'stt_catalog'}->{OUTPUT_PATH}".$arg;
	    open(FILE, ">".$cat) or die $!;
	    my $i;
	    while (my $item = $sth->fetchrow_hashref()) {
	        $i++;
	        my $line = "$cfg->{'temp'}->{'host'}/$item->{loc} ; $item->{name}\n";
	        print(FILE "$line");
	    }
	    my $line = "\n\n Total $arg: $i; \n";
	    print(FILE "$line");
	    close(FILE);
    }

    my $sth = $db->prepare("select loc, name, file_name from csv_sitemap order by file_name");
    $sth->execute();
    my $site_urls = "site_urls.csv";
    $site_urls = "$cfg->{'stt_catalog'}->{OUTPUT_PATH}".$site_urls;
    open(FILE, ">".$site_urls) or die $!;
    while (my $item = $sth->fetchrow_hashref()){
	my $line = "$cfg->{'temp'}->{'host'}/$item->{loc} ; $item->{name}\n";
        print(FILE "$line");
    }

    my @files = ('products','ext_products','category','category_brands','brands','info'); 
    foreach my $arg (@files){
	    my $csth = $db->prepare("select count(loc) as co from csv_sitemap where file_name = '".$arg.".csv'");
	    $csth->execute();
	    my $co = $csth->fetchrow_hashref();
	    my $line = "\n\n Total $arg ($arg.csv): $co->{co};";
	    print(FILE "$line");
    }
    close(FILE);

}




1;
