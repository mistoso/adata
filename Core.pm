package Core;

use warnings;
use strict;

use DB;
use Cfg;

use Core::User;
use Core::Find;
use Model::Category;
use Model::SaleMod;
use Model::Brand;
use Data::Dumper;
use Model::Comment;
use Model::Office;
use Model::Competitor;
use Model::SaleMod;
use Digest::MD5 qw(md5_hex);

sub new(){
    my $class = shift;
    bless {},
    $class;
}
#######stylus##

#sub categories_list()  {
#    my $self  = shift;
#    use Import::Categories;
#    Import::Categories->list_where( 0, 'pro_cat_id');
#}

sub seo_words(){
    use Tools;
    my $r = &Tools::get_request();
    my $url = $r->uri();

    
    return '' if $url eq '/';
    
    my $file =  $cfg->{temp}->{seo_file};

    my @b = `cat $file |grep $url | awk -F',' '{ print \$1; }' |replace '"' ''`;
    
    my $cnt = 1 + scalar @b;  
    
    my $str;
    my $str_left;

    foreach (sort @b) {
        
        $cnt--;

        $str        .= " <b>$_</b>, "    if ( $cnt % 2 == 0 );
        $str_left   .= " <em>$_</em>, "  if ( $cnt % 2 != 0 );

    }

    $str =~ s/\n//g;
    $str_left =~ s/\n//g;
    
    return ($str || '', $str_left || '');

}


sub geoip(){
  use Geo::IP;
  my $gi = Geo::IP->open('/usr/share/GeoIP/GeoIP.dat') or return '';

  return $ENV{REMOTE_ADDR}.' '.$gi->country_code_by_addr( $ENV{REMOTE_ADDR} );

# return $gi->country_code_by_addr($r->connection->remote_ip());
}

sub getip(){
  return $ENV{REMOTE_ADDR};
}

###############
sub to_json() {
    my $self = shift;
    use JSON::Syck;
    $JSON::Syck::ImplicitUnicode = 1;
    return JSON::Syck::Dump( shift );
}

sub random(){
   my $range = 2;
   my $c = int(rand($range));
   return  $c;
}

sub clean_html(){
   my $self = shift;
   my $html = shift;
    use Clean;
   return  Clean->html($html);
}

#Clean->html($sth->fetchrow_hashref);
sub brandList(){
    my $self = shift;
    return Model::Brand->list();
}

sub brands_list(){
    ## only id & name
    my $self = shift;
    return Model::Brand->activ_list();
}

sub getCategory(){
    my $self = shift;
    my $id = shift;
    return Model::Category->load($id);
}
sub getBrand(){
    my $self = shift;
    my $id = shift;
    return Model::Brand->load($id);
}
sub getSaleMod(){
    my $self = shift;
    my $id   = shift;
    my $csm  = '_salemod_'.$id;
    unless ($self->{$csm}){
    $self->{$csm} = Model::SaleMod->load($id);
    }

    return $self->{$csm};
}
sub salerList(){
    my $self = shift;
    use Model::Saler;

    return Model::Saler->list();
}
sub officeList(){
    my $self = shift;

    return Model::Office->list();
}
sub office(){
    my $self = shift;
    return Model::Office->load(1);
}
sub userList(){
    my ($self,$type) = @_;
    my $sth = $db->prepare("SELECT id FROM users WHERE type like '%".$type."%' and not deleted");

    $sth->execute();

    my @buf;
    while (my($id) = $sth->fetchrow_array){
        push @buf,Core::User->load($id);
    }

    return \@buf;
}
sub apr_pages_without_sections_list(){
    my $self = shift;
    use Model::APRPages;
    my @buf;

    my $sth = $db->prepare("select id from apr_pages where idSection = 0;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
    push @buf, Model::APRPages->load($item->{id});
    }
    return \@buf;
}
sub commentsCnt(){
    my $sth = $db->prepare("SELECT count(*) FROM comments WHERE state = 'new' AND deleted != 1 and tables = 'salemods'");
    $sth->execute();
    return $sth->fetchrow_array;
}
sub loadCatalogPrice(){
    my ($self, $idMod, $idCatalog) = @_;
    my $sth = $db->prepare("select min(price) as minprice, min(uprice) as minuprice, max(price) as maxprice, max(uprice) as maxuprice from catalogPrices where idMod = ? and idCatalog = ?;");
    $sth->execute($idMod, $idCatalog);
    my $item = $sth->fetchrow_hashref;
    return $item;
}
sub search_dec(){
    my ($self, $value, $type) = @_;

    use LWP::UserAgent;
    use Encode;
    use HTML::TokeParser;


    my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MyIE2; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',);
    my $r = $ua->get('http://morpher.ru/Demo.aspx?s='.$value);
    my $cnt = $r->content();

    my $p = HTML::TokeParser->new(\$cnt) || die "Can't open: $!";
    $p->empty_element_tags(1);

    my @buf;
    my $i;

    while (my $token = $p->get_token){
	    my $ttype = shift @{ $token };
	    if($ttype eq "S")
	    {
		my($tag, $attr, $attrseq, $rawtxt) = @{ $token };

		if($tag eq 'td' && $attr->{class} eq 'answer'){
		    my $res = $p->get_trimmed_text("/$tag");
		    $i++;
		    if($type eq 'one'){
			$res = $value;
		    }
		    push @buf,{ type => $res, val =>  $i};
		}
	    }
    }

    return \@buf;

}
sub searchall(){
    my ($class,$table,$value) = @_;
    use DB;
    use Model::Category;
    my @buf;

    if($table eq 'category'){
        my $sth = $db->prepare("SELECT id,idParent from $table  WHERE  name like '%".$value."%' order by name;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf,{
               item => Model::Category->load($item->{id}),
               parent => Model::Category->load($item->{idParent}),
              };

    }
    }

    if($table eq 'salemods'){
        my $sth = $db->prepare("SELECT id,name from $table WHERE name like '%".$value."%' and deleted != 1 order by name limit 30;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf,{
            idMod => $item->{id},
                name => $item->{name},
              }
    }
    }

    if($table eq 'brands'){
        my $sth = $db->prepare("SELECT * from $table WHERE name like '%".$value."%' order by name;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf,{
            item => Model::Brand->load($item->{id})
              }
    }
    }

    return \@buf;
}

sub categoryTop(){
    use Model::Category;

    return {
  	  childs => Model::Category->list(0)
    };

}

sub categoryListTopMenuMain(){
    my $self = shift;
    unless ($self->{_catListTopMenuMain}){
    my @buf;
    my $sth = $db->prepare('SELECT  c.id cid,
                                    c.name cname,
                                    c.alias calias,
                                    max(ct1.col) ct1colmax
                                FROM category c
                                STRAIGHT_JOIN categoryTopMenu ct
                                    ON ct.idCat = c.id
                                INNER JOIN category c1
                                    ON c.id = c1.idParent
                                STRAIGHT_JOIN categoryTopMenu ct1
                                    ON ct1.idCat = c1.id
                                WHERE c.idParent = 0
                                    AND c.isPublic = 1
                                GROUP BY c.id
                                ORDER BY ct.col;');
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf, $item;
    }
    $self->{_catListTopMenuMain} = \@buf;
    }
    return $self->{_catListTopMenuMain};
}
sub categoryListTopMenuSec(){
    my $self   = shift;
    my $cat_id = shift;
    my $cat_self = '_catListTopMenuMain'.$cat_id;
    unless ($self->{$cat_self}){
    my @buf;
    my $sth = $db->prepare('SELECT  c.id  cid,
                    c.name  cname,
                    c.alias  calias,
                    c1.id c1id,
                    c1.name  c1name,
                    c1.show_links  c1show_links,
                    c1.alias  c1alias,
                    ct.col ccol,
                    ct1.col  ct1col
                   FROM category c
              STRAIGHT_JOIN categoryTopMenu ct ON ct.idCat = c.id
                 INNER JOIN category c1 ON c.id = c1.idParent
              STRAIGHT_JOIN categoryTopMenu ct1 ON ct1.idCat = c1.id
                      WHERE c1.idParent  = ?
                        AND  ct1.col > 0
                        AND c.isPublic  = 1
                        AND c1.isPublic = 1
                   GROUP BY c1.id
                   ORDER BY ct.col, ct1.col, c1.categoryOrder ;');
    $sth->execute($cat_id);
    while (my $item = $sth->fetchrow_hashref){
        push @buf, $item;
    }
    $self->{$cat_self} = \@buf;
    }
    return $self->{$cat_self};
}
sub categoryListTopMenuTh(){
    my $self   = shift;
    my $cat_id = shift;
    my $cat_self = '_catListTopMenuTh'.$cat_id;
    unless ($self->{$cat_self}){
    my @buf;
    my $sth = $db->prepare('SELECT
                    c.id cid,
                    c.name cname,
                                    c.alias calias
                                FROM category c
                                INNER JOIN salemods sm
                                    ON sm.idCategory = c.id
                                WHERE c.idParent = ?
                                    AND c.isPublic = 1
                                    AND sm.isPublic = 1
                                    AND sm.deleted = 0
                                GROUP BY sm.idCategory
                                ORDER BY c.categoryOrder,c.name;');
    $sth->execute($cat_id);
    while (my $item = $sth->fetchrow_hashref){
        push @buf, $item;
    }
    $self->{$cat_self} = \@buf;
    }
    return $self->{$cat_self};
}
sub categoryListTopMenu(){
    my $self = shift;
    unless ($self->{_catListTopMenu}){
    my @buf;
    my $sth = $db->prepare('


    SELECT  c2.id            c2id,
                    c2.name          c2name,
                    c2.alias         c2alias,
                    c2.categoryOrder c2categoryOrder
                   FROM category c
              STRAIGHT_JOIN categoryTopMenu ct ON ct.idCat = c.id
                 INNER JOIN category c1 ON c.id = c1.idParent
              STRAIGHT_JOIN categoryTopMenu ct1 ON ct1.idCat = c1.id
                 INNER JOIN category c2 ON c2.idParent = c1.id
                 INNER JOIN salemods sm ON sm.idCategory = c2.id
                      WHERE c.idParent  = 0
                        AND c.isPublic  = 1
                        AND c1.isPublic = 1
                        AND c2.isPublic = 1
                        AND sm.isPublic = 1
                        AND sm.deleted = 0
                   GROUP BY sm.idCategory
                   ORDER BY ct.col, ct1.col, c1.categoryOrder, c2.categoryOrder;');
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf, $item;
    }
    $self->{_catListTopMenu} = \@buf;
    }
    return $self->{_catListTopMenu};
}

sub categoryList(){
    use Model::Category;
    my @buf;
    my $sth = $db->prepare('SELECT id FROM category where idParent = 0 AND isPublic = 1 and deleted != 1 order by categoryOrder,name');
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
  	  push @buf, Model::Category->load($item->{id});
    }

    return \@buf;
}

sub category(){

    use Model::Category;
    return Model::Category->list();
}

sub categoryLastLevelList(){
    use Model::Category;
    my @buf;
    my $sth = $db->prepare('select c1.id,c1.alias,c1.name from category as c1 left join category as c2 on c1.idParent = c2.id  left join category as c3 on c2.idParent = c3.id where c3.idParent = 0 and c1.deleted != 1 order by c3.categoryOrder,c2.categoryOrder,c1.categoryOrder');
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
        push @buf,$item;
    }
    return \@buf;
}
sub salemod_feature_value(){
    my $self = shift;
    my $idSaleMod = shift;
    my $idFeatureGroup  = shift;
    my $sth = $db->prepare('select * from features where idSaleMod = ? and idFeatureGroup = ?;');
    $sth->execute($idSaleMod,$idFeatureGroup);
    return $sth->fetchrow_hashref;
}

sub salemod_feature_value_content(){
    my $self = shift;
    my $idSaleMod = shift;
    my $idFeatureGroup  = shift;
    my $sth = $db->prepare('select * from content_features where idSaleMod = ? and idFeatureGroup = ?;');
    $sth->execute($idSaleMod,$idFeatureGroup);
    return $sth->fetchrow_hashref;
}

sub categorysalesList(){
    use Model::Category;
    Model::Category->saledlist();
}

sub currencyList(){
    my $self = shift;
    use Model::Currency;
    return Model::Currency->list();
}

sub currencyByCode(){
    my $self = shift;
    my $code = shift;
    use Model::Currency;
    return Model::Currency->load($code,'code');
}

sub frontCurrencyList(){
    my $self = shift;
    use Model::Currency;
    return Model::Currency->front_currency();
}

sub currDate(){
    my $self = shift;
    my $fmt = shift || '%d.%m.%y';
    use POSIX qw/strftime/;

    return strftime $fmt,localtime;
}

sub currTime(){
    use POSIX qw/strftime/;

    return strftime '%H:%M',localtime;

}

sub tomorrowDate(){
    my $self = shift;
    my $fmt = shift || '%d.%m.%y';
    use POSIX qw/strftime/;

    return strftime ($fmt,localtime(time+ 86400));
}



sub winkelwagenProducts() {
        my $self = shift;
        use Core::Winkelwagen::Product;
        return Core::Winkelwagen::Product->getAll();
}
sub winkelwagenSumm() {
        my $self = shift;
        use Core::Winkelwagen::Product;
        return Core::Winkelwagen::Product->getAllSumm();
}

sub winkelwagenCount() {
        my $self = shift;
        use Core::Winkelwagen::Product;
        return Core::Winkelwagen::Product->getCount();
}

sub winkelwagenCurrency() {
        my $self = shift;
        use Model::Currency;
        return Model::Currency->list();
}

sub getSubCategory() {
    my $self = shift;
    my $id = shift;
    use Model::Category;
    return Model::Category->list($id,'isPublic');
}

sub apr_pages_frame_pages_list() {
    my ($self,$frame) = @_;
    use Model::APRPages;
    return Model::APRTypes->frame_pages_list($frame);
}

sub apr_pages_frame_types_list() {
    my ($self,$frame) = @_;
    use Model::APRPages;
    return Model::APRTypes->frame_types_list($frame);
}

sub apr_pages_frame_sections_list() {
    my ($self,$frame) = @_;
    use Model::APRPages;
    return Model::APRTypes->frame_sections_list($frame);
}


sub prod_in_sel() {
    my $self;
    my $sth = $db->prepare("select count(s.id) as count from salemods s INNER JOIN category c ON s.idCategory = c.id where s.deleted != 1 and s.isPublic = 1 and  c.deleted != 1 and c.isPublic = 1;");
    $sth->execute();
    my ($count) = $sth->fetchrow_array;
    return $count;
}

sub get_apr_by_id(){
    my $self = shift;
    my $id = shift;
    use Model::APRPages;

    return Model::APRPages->load($id);
}



sub apr_pages_sections_list() {
    my $self = shift;
    use Model::APRPages;
    my @buf;
    my $sth = $db->prepare("select * from apr_sections order by type;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
    push @buf, $item;
    }
    return \@buf;
}

sub apr_sections_list_mperl(){
    my $self      = shift;
    my $idType    = shift;
    my @buf;
    my $sth = $db->prepare("select at.alias atalias,
                   at.name atname,
                   asec.alias asecalias,
                   asec.name asecname,
                   asec.title asectitle
                 from apr_types at INNER JOIN apr_sections asec ON at.id = asec.type where at.id = 1");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
    push @buf, $item;
    }
    return \@buf;
}


sub cat_sec_count(){
    my @buf;
    my $sth = $db->prepare("SELECT count(distinct(cs.id)) scc
                              FROM category c
                INNER JOIN category cs
                    ON c.id = cs.idParent
            INNER JOIN category as ct
                    ON ct.idParent = cs.id
            INNER JOIN salemods sm
                    ON ct.id = sm.idCategory
                 where c.idParent = 0
                   and cs.deleted != 1
                   and c.deleted != 1
                   and ct.deleted != 1
                   and sm.deleted != 1
                   and cs.isPublic = 1
                   and c.isPublic = 1
                   AND ct.isPublic = 1
                   and sm.isPublic = 1
                   AND c.idParent = 0
                   order by c.categoryOrder, cs.categoryOrder;");
    $sth->execute();
    my $item = $sth->fetchrow_hashref;
    return $item->{scc};
}

sub cat_sec_list(){
    my @buf;
    my $sth = $db->prepare("SELECT cs.id as csid
                              FROM category c
                INNER JOIN category cs
                    ON c.id = cs.idParent
            INNER JOIN category as ct
                    ON ct.idParent = cs.id
            INNER JOIN salemods sm
                    ON ct.id = sm.idCategory
                 where c.idParent = 0
                   and cs.deleted != 1
                   and c.deleted != 1
                   and ct.deleted != 1
                   and sm.deleted != 1
                   and cs.isPublic = 1
                   and c.isPublic = 1
                   AND ct.isPublic = 1
                   and sm.isPublic = 1
                   AND c.idParent = 0
                   group by cs.id
              order by c.categoryOrder, cs.categoryOrder;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
    push @buf, Model::Category->load($item->{csid});
    }
    return \@buf;
}

sub apr_pages_sections_list_select() {
    my $self = shift;
    use Model::APRPages;
    my @buf;
    my $sth = $db->prepare("select * from apr_sections order by type;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
    push @buf,{ item => $item,
            type => Model::APRTypes->load($item->{type}),
          }
    }
    return \@buf;
}

sub apr_pages_sections_list_select_front() {
    my ( $self, $type_id ) = @_;
    use Model::APRPages;
    my @buf;
    my $sth = $db->prepare("select * from apr_sections where type = ? and isPublic = 1 and deleted != 1 order by type, sort;");
    $sth->execute($type_id);
    while (my $item = $sth->fetchrow_hashref){
    push @buf,{ item => $item,
            type => Model::APRTypes->load($item->{type}),
          }
    }
    return \@buf;
}


sub apr_pages_banner_list_front() {
    my ($self, $type_id, $category_id, $section_id, $limit, $order) = @_;
    use Model::APRPages;
    my @buf;

    if (!$order) {
        $order = " ORDER BY aprp.date_from DESC, aprp.name";
    } else {
        $order = " ORDER BY RAND()";
    }
    my $limit_string;

    if($limit =~ /^\d+$/){
    $limit_string       = ( $limit       == 0 ? "  " : "LIMIT $limit" );
    }
    my $section_string  = ( $section_id  == 0 ? "!=" : "=" );

    my $myy = "SELECT distinct(aprp.id)
              FROM apr_types aprt
    INNER JOIN apr_sections aprs ON aprs.type = aprt.id
    INNER JOIN apr_pages aprp ON aprp.idCategory = aprs.id
             WHERE aprt.id = ?
           AND aprs.id ".$section_string." ?
               AND aprs.isPublic != 0
               AND aprp.isPublic != 0
          $order
      ".$limit_string;
    my $sth = $db->prepare("$myy");
    $sth->execute($type_id, $section_id);
    while (my $item = $sth->fetchrow_hashref){
    push @buf, Model::APRPages->load($item->{id});
    }
    return \@buf;
}


sub apr_pages_banner_list() {
    my ($self, $type_id, $category_id, $section_id, $limit) = @_;
    use Model::APRPages;
    my @buf;
    my $order = "ORDER BY aprt.sort,
              aprs.sort,
                  aprs.name,
                  aprp.date_from DESC,
                  aprp.name";
    my $limit_string;

    if($limit ne 'rand' && $limit =~ /^\d+$/){
    $limit_string       = ( $limit  == 0 ? "  " : "LIMIT $limit" );
    }

    if($limit eq 'rand'){
    $limit_string = "LIMIT 1";
    $order = "ORDER BY RAND()";
    }
    my $by_url;
    if( $type_id eq 'right' )
    {
    $type_id = 14;
    $by_url = "AND by_url = '".$category_id."'";
    $category_id = 0;
    }

    my $category_string = ( $category_id == 0 ? "!=" : "=" );
    my $section_string  = ( $section_id  == 0 ? "!=" : "=" );

    my $myy = "SELECT
           distinct(aprp.id)
              FROM apr_types aprt
    INNER JOIN apr_sections aprs ON aprs.type = aprt.id
    INNER JOIN apr_pages aprp ON aprp.idCategory = aprs.id
    LEFT JOIN apr_contacts aprc ON aprc.idPage = aprp.id
             WHERE aprt.id = ?
           AND aprc.idCategory ".$category_string." ?
           AND aprs.id ".$section_string." ?
           ".$by_url."
           AND aprc.deleted != 1
               AND aprs.isPublic != 0
               AND aprp.isPublic != 0
          $order
      ".$limit_string;
    my $sth = $db->prepare("$myy");
    $sth->execute($type_id, $category_id, $section_id);
    while (my $item = $sth->fetchrow_hashref){
    push @buf, Model::APRPages->load($item->{id});
    }
    return \@buf;
}


sub apr_by_url{
    my ($self, $url, $section_id) = @_;
    my @buf;
    my $extsql;

    if($section_id){
  	  $extsql .= " AND ap.idCategory = ".$section_id." ";
    }

    my $sth = $db->prepare("select  ap.name as name,  ap.title as title,  ap.page_text as page_text from apr_contacts ac INNER JOIN apr_pages ap ON ac.idPage = ap.id where ac.by_url = ? $extsql  and  ap.isPublic = 1 and ac.deleted != 1;");
    $sth->execute($url);

    while (my $item = $sth->fetchrow_hashref){
      push @buf, $item;
  #   push @buf, Model::APRPages->load($item->{id});
    }

    return \@buf;
}

sub cat_model(){
    my ($self, $cat_id) = @_;
    my $cat = Model::Category->load($cat_id);
    return $cat;
}


sub count() {
    my $self = shift;
    use Base::TiedTwoCount;
    unless ( $self->{_count_init} ) {
        tie $self->{_count}, "Base::TiedTwoCount";
        $self->{_count_init} = 1;
    }
    $self->{_count};
}

sub video(){
    my ($self, $table, $idTable) = @_;
    my @buf;
    my $sth = $db->prepare("select * from video where table_name = ? and idTable = ?");
    $sth->execute($table, $idTable);
    while (my $item = $sth->fetchrow_hashref){
    push @buf, $item;
    }
    return \@buf;
}



sub get_salemod(){
    my $self = shift;

    use Model::SaleMod;

    return Model::SaleMod->load(shift);
}
sub bottom_links(){
    my $self = shift;
    my @buffer;
    unless($self->{_bottom_links}){
    my $dth = $db->prepare("select c.id from category c
                    INNER JOIN catalogCategory ctc ON c.id = ctc.idCat
                    INNER JOIN catalog ct ON ct.id = ctc.idCatalog
                         where ct.bottomFrame = 1
                           and c.isPublic = 1
                           AND ctc.isPublic = 1;");
    $dth->execute();
    while (my ($id) = $dth->fetchrow_array){
        push @buffer, Model::Category->load($id);
    }
    $self->{_bottom_links} = \@buffer;
    }
    return $self->{_bottom_links};
}

sub get_settings(){
    my $self = shift;
    my $name = shift;

    my $sth = $db->prepare('select value from settings where name = ?');
    $sth->execute($name);
    my $item = $sth->fetchrow_hashref;

    return $item->{'value'};
}

sub save_settings(){
    my $self = shift;
    my $name = shift;
    my $value = shift;

    my $sth = $db->prepare('replace into settings (value,name) value (?,?)');
    $sth->execute($value,$name);

    return 1;
}

sub looks_price_products(){
    my $class = shift;
    my $prod_id = shift;
    my $price = shift;
    my $cat_id = shift;
    my $brand_id = shift;
    my $limit = shift || '100';
    my $price_min;
    my $price_max;
    my @buf;
    my $res;

    if (($price > 0) && ($price != 9999)) {
        $price_min = $price - ($price/100)*7;
        $price_max = $price + ($price/100)*7;
    }

    my $sth = $db->prepare('select id from salemods where idCategory = ? and price <= ? and price >= ? and id != ? and isPublic = 1 and deleted != 1 limit ?');
    $sth->execute($cat_id,$price_max,$price_min,$prod_id,$limit);
    while (my $id = $sth->fetchrow_array){
        push @buf,Model::SaleMod->load($id);
    }

    $sth = $db->prepare('select count(id) as cnt from salemods where idCategory = ? and price <= ? and price >= ? and id != ? and isPublic = 1 and deleted != 1');
    $sth->execute($cat_id,$price_max,$price_min,$prod_id);

    my $count = $sth->fetchrow_hashref;
    $res->{'cnt'} = $count->{'cnt'};
    $res->{'lst'} = \@buf;
    $res->{'prc'}->{'up_prc'} = $price_max;
    $res->{'prc'}->{'down_prc'} = $price_min;

    return $res;
}


sub get_url {
    my $r = &Tools::get_request();
    return $r->uri();
}


sub cats_for_ajax_search(){
    my @buf;
    my $sth = $db->prepare("SELECT c2.name as cname2,
                   c3.name as cname3,
                   c2.id as cid2,
                   c3.id as cid3
                  FROM category as c3 LEFT JOIN category as c2 on c3.idParent = c2.id
                 WHERE c3.isPublic = 1
                   AND c2.isPublic = 1
                   AND c2.idParent
              ORDER BY c2.name, c3.name;");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref){
    push @buf, $item;
    }
    return \@buf;
}

sub get_cloud_by_url(){
    my ($self,$url) = @_;
    my @buf;
    my $sth = $db->prepare("SELECT * FROM cloud_contacts cc INNER JOIN cloud_items ci ON ci.id_cloud = cc.id_cloud
                    WHERE url = ?
                      AND ci.deleted != 1
                      AND cc.deleted != 1
                 ORDER BY sort;");
    $sth->execute($url);
    while (my $item = $sth->fetchrow_hashref){
    push @buf, $item;
    }
    return \@buf;
}

sub catalog_list(){
    my $catalog = Model::Catalog->list();
    return $catalog;
}


sub catalog_get_contact(){
    my ($self, $idCatalog, $idMod) = @_;
    my $sth = $db->prepare("select * from catalogContacts where idCatalog = ? AND idMod = ? limit 1;");
    $sth->execute($idCatalog, $idMod);
    my $item = $sth->fetchrow_hashref();
    return $item;
}


sub catalog_load_contact(){
    my ($self, $idCatalog, $idMod) = @_;
    my $sth = $db->prepare("select id from catalogContacts where idCatalog = ? AND idMod = ? limit 1;");
    $sth->execute($idCatalog, $idMod);
    my $item = $sth->fetchrow_hashref();
    if($item->{id}){
    my $model = Model::CatalogContacts->load($item->{id});
    return $model;
    }
}
sub getActiveHost(){
    my ($self, $host) = @_;

    my $sth = $db->prepare("select active from outward_cod where host = ? ");
    $sth->execute($host);
    my $value = $sth->fetchrow_array();

    return $value;
}

sub getAddonCategory() {
    my $self = shift;
    my $idParent = shift;
    my @buf;

    my $sth = $db->prepare("select idCategory from category_addons where idParent = ? ;");
    $sth->execute($idParent);
    while (my ($id) = $sth->fetchrow_array){
        push @buf,Model::Category->load($id);
    }

    return \@buf;
}

sub set_idImageById(){
    my ($self, $table, $idImage, $idTable ) = @_;
    if($table eq 'salemods'){
    if( $idImage =~ /^\d+$/ && $idTable =~ /^\d+$/){
        my $sth = $db->prepare("update ".$table." set idImage = ? where id = ?");
        $sth->execute($idImage, $idTable);
    }
    }
}


sub get_gallery(){
     my ($self,$name) = @_;
     my $model = Core::Gallery->new($name);
     return $model;
}

sub get_features_count {
    my $selfs = shift;
    my $idSaleMod = shift;

    my $sth = $db->prepare("select count(*) from features where idSalemod = ? and value <> '' ");
    $sth->execute($idSaleMod);
    my ($count) = $sth->fetchrow_array();

    return $count;
}

sub getBaseMod() {
    my $self = shift;
    my $id = shift;

    my $sth = $db->prepare("select * from salemods where id = ? limit 1;");
    $sth->execute($id);
    my $item = $sth->fetchrow_hashref;
    return $item;
}

sub sales_rerite(){
    my $self = shift;
    my $idCategory = shift;
    my @buf;
    my $sth = $db->prepare('select id, name, alias from salemods name where idCategory = ? order by name');
    $sth->execute($idCategory);
    while (my $item = $sth->fetchrow_hashref){
    push @buf,$item;
    }
    return \@buf;
}

sub cat_comments(){
    my $self = shift;
    my $table = shift;
    my $id = shift;
    my @buf;
    my $sth = $db->prepare("select count(comments.id) as cnt ,comments.idCategory,category.name as name from comments inner join category on comments.idCategory = category.id where tables = 'salemods' and not comments.deleted group by comments.idCategory order by category.name");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref()){
        my $sth = $db->prepare("select count(id) from comments where state = 'new' and tables = 'salemods' and not deleted and idCategory = ?");
        $sth->execute($item->{'idCategory'});
        $item->{'ncnt'} = $sth->fetchrow_array();
        push @buf,$item;
    }
    return \@buf;
}

sub get_comments_text_count(){
    my $sth = $db->prepare("select count(*) from comment_text;");
    $sth->execute();
    return $sth->fetchrow_array();
}

sub get_comments_count(){
    my $sth = $db->prepare("select count(*) from comments;");
    $sth->execute();
    return $sth->fetchrow_array();
}


sub page_comments(){
    my $self = shift;
    my $table = shift;
    my $id = shift;
    my @buf;
    my $sth = $db->prepare("select count(comments.id) as cnt ,comments.idCategory,apr_sections.name as name from comments inner join apr_sections on comments.idCategory = apr_sections.id where tables = 'apr_pages' and not comments.deleted group by comments.idCategory");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref()){
        my $sth = $db->prepare("select count(id) from comments where state = 'new' and tables = 'apr_pages' and not deleted and idCategory = ?");
        $sth->execute($item->{'idCategory'});
        $item->{'ncnt'} = $sth->fetchrow_array();
        push @buf,$item;
    }
    return \@buf;
}

sub getCompareDataFromSalemodsByFeatureId(){
    my $self = shift;
    my $salemods = shift;
    my $fid = shift;
    my @resultValues = ();

    foreach my $mod (@{$salemods}){
        foreach my $featureGroup (@{$mod->{featureGroups}}){
            foreach my $feature (@{$featureGroup->{childs}}){
                if ($feature->{id} eq $fid){
                    push @resultValues, {value => $feature->{value}, id => $feature->{id} }
                }
            }
        }
    }

    return \@resultValues;
}

sub getCommentForBanner(){
    my $self = shift;
    my $table = shift;
    my $cat = shift;
    my $brand = shift;
    my $limit = shift;

	if (($table eq 'salemods') && ($cat ne '')){
        my $mas_cat = '';

        my $sth = $db->prepare("select id from category where not deleted and isPublic and idParent = ?");
        $sth->execute($cat);

        while (my $id = $sth->fetchrow_array()){
            $mas_cat .= $id.",";
        }

        if ($mas_cat ne ''){
            chop($mas_cat);
            $cat = $mas_cat;
        }

    }

    return Model::Comment->last_comments($table,$cat,$brand,$limit);
}

sub newOrdersCount(){
    my $sth = $db->prepare("select count(distinct(p.idOrder)) from new_orders_positions as p inner join new_orders as o on o.id = p.idOrder inner join salemods as s on s.id = p.idMod where p.state = 'new' and not p.deleted and not o.deleted and not s.deleted");
    $sth->execute();
    my $item = $sth->fetchrow_array();
    return $item;
}

sub new_parasite(){
    my $sth = $db->prepare("select count(id) from comments where tables = 'parasite' and state = 'new' and not deleted ");
    $sth->execute();
    my $item = $sth->fetchrow_array();
    return $item;
}

sub getLastPriceUpdatesStat(){
    my @buf;
    my $sth = $db->prepare("select s.name as sname,s.id as sid,u.name as uname,su.updnum,su.newnum,su.updated from salerprices_updates as su inner join salers as s on s.id = su.idSaler left join users as u on u.id = su.idOperator order by updated desc limit 100");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref()){
        push @buf,$item;
    }
    return \@buf;
}

sub get_salemod_features_short() {
    my $self = shift;
    my $sm_id = shift;
    my $sm_id_cat = shift;
    my $sm_self = '_features_desc'.$sm_id_cat.'_'.$sm_id;
    unless ($self->{$sm_self} ){
    my $sth = $db->prepare("select group_concat(fg.name,' ',fl.title) as title
            from feature_groups fg
          INNER JOIN filters fl ON fg.id = fl.idParent
          INNER JOIN filters_cache flc ON flc.idFilter = fl.id
               WHERE flc.idSalemod = ?
                 AND fg.idCategory = ?
                 AND fg.searchable = 1");
    $sth->execute($sm_id,$sm_id_cat);
    $self->{$sm_self}  = Clean->html($sth->fetchrow_hashref);
    }
    return $self->{$sm_self};
}

sub categoryListBottomMenu(){
    my $self = shift;
    my $column = shift;
    my @buf;

    my $sth = $db->prepare("select concat(c1.alias,'/',c.alias)as alias ,c.name from categoryTopMenu as ctm inner join category as c on ctm.idCat = c.id inner join category as c1 on c1.id = c.idParent where col2 = ? and c.isPublic = 1");
    $sth->execute($column);
    while (my $item = $sth->fetchrow_hashref()){
        push @buf,$item;
    }

    return \@buf;
}

sub orderpositionsHistory(){
    my $self = shift;
    my $posid = shift;
    my @buf;

    my $sth = $db->prepare("select IF(u.lastName != '',u.lastName,u.name) as name,oph.updated,oph.changes from new_orders_positions_history as oph inner join users as u on u.id = oph.idOwner where oph.idOrderPos = ? order by oph.updated asc");
    $sth->execute($posid);
    while (my $item = $sth->fetchrow_hashref()){
        push @buf,$item;
    }
    return \@buf;
}

sub categoryMainFiltersList(){
    my $self   = shift;
    my $cat_id = shift;

    my $cat_self = '_categoryMainFiltersList'.$cat_id;

    unless ($self->{$cat_self}){
        my @buf;
        my $sth = $db->prepare('select fg.name as fgname, f.title as fname, f.id as fid from filters f INNER JOIN feature_groups fg ON fg.id = f.idParent where f.onidCategory = ?;');
        $sth->execute($cat_id);
        while (my $item = $sth->fetchrow_hashref){
            push @buf, $item;
        }
        $self->{$cat_self} = \@buf;
    }

    return $self->{$cat_self};
}

sub get_content_task_for_mods(){
    my $self   = shift;
    my $mod_id = shift;

    my @buf;
    my $sth = $db->prepare('select c.name,t.state from content_tasks t inner join content_users c on t.idcontent = c.id where t.idSaleMod = ?;');
    $sth->execute($mod_id);
    while (my $item = $sth->fetchrow_hashref){
        push @buf, $item;
    }

    return \@buf;
}
sub getLastOrderPositions(){
    my $self   = shift;
    my @buf;
    my $sth = $db->prepare('select distinct(idMod) from new_orders_positions order by id desc limit 5');
    $sth->execute();
    while (my $id = $sth->fetchrow_array){
        push @buf, Model::SaleMod->load($id);
    }

    return \@buf;
}

sub getsslinks(){
    my $self   = shift;
    my $r = &Tools::get_request();
    my $ss_uri = $r->uri();
    my $stext = "<!-- ss_links_call_ok --> ";
    my $md5_hash = md5_hex($ss_uri);
    my $ss_storage_filename = substr $md5_hash, 0, 2;
    warn "\n\n\n ------------ open FILE $cfg->{'stt_catalog'}->{'OUTPUT_PATH'}linker/links/$ss_storage_filename.db";
    open LINKS, "<".$cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/links/".$ss_storage_filename.".db";
    while (<LINKS>) {
    chomp;
    my ($url, $link, $text, $text_before, $text_after) = split("\t");
        if ($url && $link && $text) {
        $url  = &str_replace('url:', '', $url);
        $link = &str_replace('link:', '', $link);
        $text = &str_replace('text:', '', $text);
        $text_before = &str_replace('text_before:', '', $text_before);
        $text_after = &str_replace('text_after:', '', $text_after);
            if ($ss_uri eq $url) {
                $stext .= "<!--lb-->$text_before <a href='$link'>$text</a> $text_after<!--le--> ";
            }
        }
    }
    close LINKS;
    $stext .= " <!-- ss_links_call_end -->";
    return $stext;
}


sub getstexts(){
    my $self   = shift;
    my $r = &Tools::get_request();
    my $ss_uri = $r->uri();
    my $stext = "<!-- ss_texts_call_ok --> ";
    my $md5_hash = md5_hex($ss_uri);
    my $ss_storage_filename = substr $md5_hash, 0, 2;
    warn "\n\n\n ------------ open FILE $cfg->{'stt_catalog'}->{'OUTPUT_PATH'}linker/texts/$ss_storage_filename.db";

    open LINKS, "<".$cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/texts/".$ss_storage_filename.".db";
    while (<LINKS>) {
    my ($domain, $uri, $text, $weight) = split("\t");
    if ($domain && $uri && $text) {
        $domain = &str_replace('domain:', '', $domain);
        $uri    = &str_replace('uri:', '', $uri);
        $text   = &str_replace('text:', '', $text);
        $weight = &str_replace('weight:', '', $weight);
        if ($ss_uri eq $uri && (($domain eq '') || ($domain eq $ENV{'HTTP_HOST'}))) {
            $stext .= "$text ";
        }
    }
    }
    close LINKS;
    $stext .= " <!-- ss_texts_call_end -->";
    return $stext;
}

sub getsinternals(){
    my $self   = shift;

    use Text::Unidecode qw(unidecode);
    use HTML::Entities qw(decode_entities);

    my $r = &Tools::get_request();
    my $ss_uri = $r->uri();

    my $stext = "<!-- ss_internals_call_ok --> ";
    my $md5_hash = md5_hex($ss_uri);
    my $ss_storage_filename = substr $md5_hash, 0, 2;
    warn "\n\n\n ------------ open FILE $cfg->{'stt_catalog'}->{'OUTPUT_PATH'}linker/internals/$ss_storage_filename.db";

    open LINKS, "<".$cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/internal/".$ss_storage_filename.".db";
    while (<LINKS>) {
    my ($domain, $uri, $link) = split("\t");

    if ($domain && $uri && $link) {
        $domain = &str_replace('domain:', '', $domain);
        $uri    = &str_replace('uri:', '', $uri);
        $link   = &str_replace('link:', '', $link);
        if ($ss_uri eq $uri && (($domain eq '') || ($domain eq $ENV{'HTTP_HOST'}))) {
        $stext .=  "$link ";
        }
    }
    }

    close LINKS;
    $stext .= " <!-- ss_internals_call_end -->";
    $stext =~ s/lt;/</g;
    $stext =~ s/gt;/>/g;
#    return unidecode(decode_entities($stext));
    return $stext;
}




sub str_replace() {

    my $replace_this 	= shift;
    my $with_this  		= shift;

    my $string   		= shift;

    my $length 			= length($string);
    my $target 			= length($replace_this);

    for(my $i=0; $i<$length - $target + 1; $i++) {
  	  if( substr( $string, $i, $target ) eq $replace_this ) {

        $string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
        return $string;
  	  }
    }
    return $string;
}

sub run_script(){
        my $self = shift;
        my $script = shift;
        my @res = ();
        @res = `$script`;

        return @res;
}


######## Competitors

sub competitorsList(){
    my $self = shift;
    use Model::Competitor;
    $self->{_competitors} ||= Model::Competitor->list();
}

sub competitorCatList(){
    my $self = shift;
    my ( $id, $type ) = @_;
    unless ($self->{_cat_list}){
    my $sth = $db->prepare('select cat_id from '.$type.' where comp_id = ?');
    $sth->execute($id);
    my $class = 'Model::Competitor::'.$type;
    while(my ($cat_id) = $sth->fetchrow_array ){
        push @{$self->{_cat_list}},$class->load($cat_id,'cat_id');
    }
    }
    return $self->{_cat_list};
}

sub competitorsProcessedCatList(){
  my $self = shift;
  unless ($self->{_proc_cat_list}){
    my $sth = $db->prepare('SELECT distinct(cat_id) FROM competitors_prices where idMod');
    $sth->execute();
    while(my ($id) = $sth->fetchrow_array ){
    push @{$self->{_proc_cat_list}},$id;
    }
  }
  return $self->{_proc_cat_list};
}

sub competitorsProcessedProdList()
{
    my $self = shift;
    my ( $cat_id ) = @_;
    my @competitors;

    my @products;
    my @products_first;
    my @products_second;

    use Model::Competitor;

    my $exth = $db->prepare('select distinct(cp.idCompetitor) as idCompetitor,c.name as Name from competitors_prices as cp JOIN competitors as c ON c.id=cp.idCompetitor where cp.cat_id = ? AND cp.idMod');
    $exth->execute($cat_id);
    while ( my $item = $exth->fetchrow_hashref ){
        push @competitors,{'idComp' => $item->{idCompetitor}, 'Name' => $item->{Name}};
    }

    my $pxth = $db->prepare('select idMod,id,cat_id,idCompetitor,price from competitors_prices where cat_id = ? AND idCompetitor in(1,2) and idMod group by idMod;');
    $pxth->execute($cat_id);

    while ( my $pitem = $pxth->fetchrow_hashref ){

    my $oxth = $db->prepare('SELECT price, name FROM salemods WHERE id = ?');
    $oxth->execute($pitem->{idMod});
    my ( $mtprice, $mtname ) =  $oxth->fetchrow_array;

       push @products,{'idComp'  => $pitem->{idMod},
                       'model'   => "$mtname $pitem->{idMod}",
                        'id'      => "$pitem->{idMod}",
                        'mtprice' => $mtprice,
              };
    }
    my @sproducts = sort {uc($a->{model}) cmp uc($b->{model})} @products;



    my $mass = {'competitors' => \@competitors, 'products' => \@sproducts};
    return $mass;
}

sub search_for_comp(){
    my $self   = shift;
    my $frase  = shift;

#    $frase     =~ s/\s/|/mg;
    $frase =~ s/[^\w]//go;
#    print $frase."<BR>";
    use Search;


#   my $srch = Core::Find->new();
#   $frase =~ s/[^\w]//go;
#   $srch->{'frase'} = $frase;
#   my @buf;
#   $srch->search_salemod_pname();
#   foreach (@{$srch->{'ids'}}) { push @buf,Model::SaleMod->load($_); }

    my $res = Search->new->search_comp( $frase );

    return $res or $frase;

}


sub search_on_st(){
    my $self = shift;
    my $frase  = shift;
    my $srch = Core::Find->new();
    $frase =~ s/[^\w]//go;
    $srch->{'frase'} = $frase;
    my @buf;
    $srch->search_salemod_pname();
    foreach (@{$srch->{'ids'}}) {
        push @buf,Model::SaleMod->load($_);
    }
    return \@buf;
}


sub salemodStat(){
    my $self = shift;
    my $result;

    my $sxth = $db->prepare('select count(*) from salemods where isPublic = 1 and price > 0;');
    $sxth->execute();

    $result->{'smod'} = $sxth->fetchrow_array();

    my $cxth = $db->prepare('select count(DISTINCT(idCategory)) from salemods where isPublic = 1 and price > 0;');
    $cxth->execute();

    $result->{'cat'} = $cxth->fetchrow_array();

    my $bxth = $db->prepare('select count(DISTINCT(idBrand)) from salemods where isPublic = 1 and price > 0;');
    $bxth->execute();

    $result->{'brand'} = $bxth->fetchrow_array();

    return $result;
}

sub get_apr_sec_by_alias(){
	my $self = shift;
	my $alias = shift;
	use Model::APRPages ;
	my $section = Model::APRSections->load($alias,'alias');
	return $section;
}

sub trustlink(){
#	my $self = shift;
#
#	my $o = {};
#	$o->{charset} = 'cp1251';
#	$o->{TRUSTLINK_USER} = '9494ff0b7b2a0e3bff593ca80a29394cba303f9b';
#	push @INC, "/var/www/goodcat.com.ua/var/9494ff0b7b2a0e3bff593ca80a29394cba303f9b";
#	use TrustlinkClient;
#	my $trustlink = new TrustlinkClient($o);
#	undef($o);
#	return $trustlink->build_links();
}


1;
