package Entry::Main;

use warnings;
use strict;

use Apache2::Const      qw/OK M_GET NOT_FOUND HTTP_MOVED_PERMANENTLY/;
use Core::Template      qw/get_template/;


use Apache2::SubRequest;
use Apache2::RequestRec;

use Logger;
use Core::Logs;
use Core::DB;
use Tools;
use Data::Dumper;
use Core::SalemodsSort;
use Core::Session;
use Model::Category;
use Model::Brand;
use Core::User;
use Cfg;
use Core::Meta;
use Core::Pager;
use Core::Filters;
use Model::Comment;
use Core::Comparison;
use Core::Mail;
use Core;
use Model::Meta::Url;

our ( $r, $s, $user, $args, $AA );


$AA     = " \\_ \\w \\d \\- \\+ \\( \\) \\: \\,";

sub handler(){
    $r = shift; 
    my $req = $r->uri();
    $r->content_type('text/html');

    &main_301($req);

    $args = &Tools::get_request_params($r);

    $s    = Core::Session->instance(1);
    
    #$s = Sessions::Client->new($r);
    
    $user = Core::User->current();

    Core::Meta->instance(1,$req); #sadefault url

    my %content = (
    	'\\/' => *main_index{CODE},
    	"\\/comments\\.chtm"                                    => *main_comments{CODE},
        "\\/compare\\.shtm"                                     => *main_compare{CODE},
        "\\/([$AA]+)\\.html"                                    => *main_category{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/([$AA]+)\\.html"              => *main_sales_brands{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/(\\d+)_([124])\\.html"         => *main_sales_paged{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\.html"                         => *main_sales_nonpaged{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/show_(\\w+)\\.html"           => *main_sales_show{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/sort_(\\w+)\\.html"           => *main_sales_sort{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/on_page_(\\w+)\\.shtml"       => *main_sales_on_page{CODE},


        "\\/([$AA]+)\\/([$AA]+)\\/([$AA]+)\\/(\\d+)_(\\d+)\\.html"      => *main_sales_brands_paged{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/([$AA]+)\\/show_(\\w+)\\.html"        => *main_sales_brands_show{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/([$AA]+)\\/on_page_(\\w+)\\.shtml"    => *main_sales_brands_on_page{CODE},
        "\\/([$AA]+)\\/([$AA]+)\\/([$AA]+)\\/sort_(\\w+)\\.html"        => *main_sales_brands_sort{CODE},


        "\\/([$AA]+)\\.htm" => *main_salemod_desc{CODE},

        "\\/comment\\/([$AA]+)\\.htm" => *main_salemod_comment{CODE},
    	"\\/video\\/([$AA]+)\\.htm" => *main_salemod_video{CODE},
    	"\\/salemod_img\\/([$AA]+)\\.htm" => *main_salemod_img{CODE},

    	"\\/compare\\/([$AA]+)\\.htm" => *main_add_prod_to_comparison{CODE},
    	"\\/compare\\/([$AA]+)\\.dhtm" => *main_del_prod_from_comparison{CODE},
    	"\\/compare\\/([$AA]+)\\.adhtm" => *main_adel_prod_from_comparison{CODE},

    	"\\/compare\\/([$AA]+)\\/([$AA]+)\\.dahtm" => *main_comparison_clean{CODE},

    	"\\/get_next_slide\\.htm" => *main_salemods_next_slide{CODE},

    	"\\/compare\\.dhtm" => *main_comparison_clean{CODE},
    	"\\/compare\\.dhtml" => *main_comparison_clean_active{CODE},

    	'\\/sendmail' => *main_sendmail{CODE},
    );

    foreach my $reg (keys %content){
		if (my @args = ($req =~ /^$reg$/)){
			return &{$content{$reg}}(@args);
			return $r if $r;
		}
	}

    return NOT_FOUND;
}

sub redirect($){
    $s->save();
    $r->method('GET');
    $r->method_number(M_GET);
    $r->internal_redirect_handler(shift);
	exit;
}

sub main_redirect(){
    &main_301($r->uri());
}

sub not_found(){
    return NOT_FOUND;
}

sub main_301(){
	my $sth = $db->prepare('select lto from page_redirect where lfr = ?;');
    $sth->execute(shift);
	my $url = $sth->fetchrow_array;
    if( $url ) {
        &main_redirect_301( $url );
    }
}
sub main_redirect_301(){
	$r->no_cache(1);
	$r->status(Apache2::Const::HTTP_MOVED_PERMANENTLY);
	$r->headers_out->add(Location => shift);
    exit;
}

sub main_index() {
    get_template( 'frontoffice/templates/index' => $r, 'main_index' => '1' );
    return OK;
}

sub main_salemod_img(){
    get_template( 'frontoffice/templates/salemod/salemod_img' => $r, 'salemod' => Model::SaleMod->load( shift, 'alias' ) );
    return OK;
}



sub main_look_price(){
    my $salemod = Model::SaleMod->load(shift,'alias') or return NOT_FOUND;
    my $fsalemods = Core->looks_price_products($salemod->{'id'},$salemod->{'price'},$salemod->{'idCategory'},$salemod->{'idBrand'} );

    get_template(
        'frontoffice/templates/collective' => $r,
        'look'          => 'look_price',
        'finditem'      => $fsalemods->{'lst'},
        'product'       => $salemod,
        'price_limits'  => $fsalemods->{'prc'},
    );

    return OK;
}

sub main_salemod_desc(){
    &main_salemod(shift,'desc');
    return OK;
}
sub main_salemod_comment(){
    &main_salemod(shift,'comment');
    return OK;
}
sub main_salemod_video(){
    &main_salemod(shift,'video');
    return OK;
}

sub main_salemod() {
    my $alias   = shift;
    my $look    = shift;

    my $model = Model::SaleMod->load($alias,'alias')
                    or return NOT_FOUND;

    my $meta  = Model::Meta::Url->load( $r->uri,'url' );

    Core::Meta->instance->change($model,'product')      if !$meta and $look eq 'desc';
    Core::Meta->instance->change($model,'productvideo') if !$meta and $look eq 'video';
    Core::Meta->instance->change($model,'productotziv') if !$meta and $look eq 'comment';

    get_template(
	    'frontoffice/templates/salemod' => $r,
    	   salemod => $model,
	       subcategory => $model->category,
	       category => $model->category,
    	   look => $look,
    );

    return OK;
}

sub main_category(){

    my $model = Model::Category->load(  shift, 'alias' ) or return NOT_FOUND;

    my $meta  = Model::Meta::Url->load( $r->uri, 'url' );
    Core::Meta->instance->change( $model->{alias}, 'cat' ) unless $meta;



    my $sth = $db->prepare("select
			    c1.id c1id,
			    c2.id c2id,
			    c1.alias c1alias,
			    c2.alias c2alias,
			    b.alias balias,
			    c1.name c1name,
			    c2.name c2name,
			    b.name bname,
			    count(sm.id) smcount,
			    min(sm.price) c2minprice,
			    max(sm.price) c2maxprice,
			    g.id as gid
		       FROM category c1
         INNER JOIN category c2 ON c1.id = c2.idParent
		 INNER JOIN salemods sm ON c2.id = sm.idCategory
		 INNER JOIN brands b ON sm.idBrand = b.id
		  LEFT JOIN gallery g ON concat('category/',c2.alias) = g.name
		      WHERE c1.id = ?
		        AND sm.isPublic = 1
		        AND c2.isPublic = 1
		   GROUP BY c2.id, b.id
		   ORDER BY c2.categoryOrder, c2.alias, b.alias;");

    $sth->execute( $model->{id} );

    my @buf = ();

    while (my $item = $sth->fetchrow_hashref){
	   push @buf, $item;
    }

    get_template(
	    'frontoffice/templates/category' => $r,
	    'category'     => $model,
	    'categorys'    => \@buf,
	    'main'         => '1',
	    'look'         => "main",
	);

    return OK;
}

sub main_sales(){
    my $a = shift;


    my @buffer;
    my $sql;
    my $temp;

    Model::Category->load($a->{category},'alias') or return NOT_FOUND;

    my $category = Model::Category->load($a->{subcategory},'alias') or return NOT_FOUND;

    $category->{brand} = $a->{brand};

    my $meta = Model::Meta::Url->load( $r->uri,'url' );

    unless( $meta ){
    	Core::Meta->instance->change($category,'childcat');
    }

    Core::Meta->instance->change($category,'childcat') unless  $meta;

    if($a->{brand}->{id} > 0 )
    {
    	$sql = ' AND s.idBrand = '.$a->{brand}->{id}.' ';
    }

    my $sort = Core::SalemodsSort->session_sales_sort({
                category    => $a->{category},
                subcategory => \$category,
                sort        => $a->{sort},
                show        => $a->{show},
                limit       => '124',
                brand       => $a->{brand},
                on_page     => $a->{on_page},
                user        => $user,
    });


    my ( $order, $desc ) = split( /_/, $sort->{sort} );

    $sql .= ' AND s.price > 0 '    if $sort->{price} eq 'only_price';
    $sql .= ' AND s.isPublic = 1 ' if $sort->{price} eq 'only_price';

    $sql .= ' ORDER BY s.'.$order.' '.$desc;

    $temp = ($sort->{on_page} eq 'cols') ? 'sales_list_cols' : 'sales_list';

    ## $category->{product_list_cols} if this value equal 1, show rows, unless cols
    ##print $sort->{on_page}."=".Dumper(
    #filters

    my $filters = Core::Filters->new( $category->{id} );

    if ($args->{a}){
        $a->{page} = 1;
        $filters->set($args->{a},$args->{id});
    }


    my $price_filter = $user->session->get('price_filter');

    $a->{page} = 1 if ($args->{min} or $args->{max});

    if ((not defined $args->{min}) and (not defined $args->{max})) {
        if ($category->{id} eq $price_filter->{cat}) {
        $args->{min} = $price_filter->{min} if $price_filter->{min} =~ /^\d+$/;
        $args->{max} = $price_filter->{max} if $price_filter->{max} =~ /^\d+$/;
    }
    }

    my $price_sql = '';
    my $minprice = '';
    my $maxprice = '';

    if ($args->{min} =~ /^\d+$/ and $args->{max} =~ /^\d+$/) {
        $user->session->set('price_filter',{'cat' => $category->{id}, 'min' => $args->{min}, 'max' => $args->{max}});
        $price_sql = ' and (s.price between "'.$args->{min}.'" and "'.$args->{max}.'" and s.price != 9999) ';
        $minprice = $args->{min};
        $maxprice = $args->{max};
    }
    elsif ($args->{min} =~ /^\d+$/) {
       $user->session->set('price_filter',{'cat' => $category->{id}, 'min' => $args->{min}, 'max' => ''});
        $price_sql = ' and (s.price > "'.$args->{min}.'" and s.price != 9999) ';
        $minprice = $args->{min};
    }
    elsif ($args->{max} =~ /^\d+$/) {
       $user->session->set('price_filter',{'cat' => $category->{id}, 'max' => $args->{min}, 'min' => ''});
        $price_sql = ' and (s.price < "'.$args->{max}.'" and s.price != 9999) ';
        $maxprice = $args->{max};
    }
    else {
       $user->session->set('price_filter',{'cat' => $category->{id}, 'min' => '', 'max' => ''});
    }

    my $query = '';
    my $filter_mask_query = '';

    $filters->set_sql();

    my $pager = Core::Pager->new( $a->{page}, 124 );

    if (my ($join,$where) = ( $filters->get_sql_join(), $filters->get_sql_where() ) ) {
            $query = '
                   SELECT SQL_CALC_FOUND_ROWS s.name sname,
                   s.id sid,
                   s.alias salias,
                   s.DescriptionFull sdescription,
                   s.price sprice,
                   s.GalleryName sGalleryName,
                   s.idImage sidImage,
                   s.rating rating,
                   s.mpn mpn,
                   b.name bname,
                   s.baseId sbaseId,
                   s.garanty sgaranty,
                   b.alias balias
                   FROM salemods s
                   INNER JOIN brands b ON b.id = s.idBrand
                   '.$join.' WHERE s.idCategory = ? '.$price_sql.' '.$where.' '.$sql.' LIMIT '.$pager->getOffset().','.$pager->getLimit();

            $filter_mask_query = 'insert ignore into filters_mask'.$$.'(idSalemod) SELECT s.id
                   FROM salemods s
                   INNER JOIN brands ON brands.id = s.idBrand '.$join.'
                   WHERE s.idCategory = ? '.$price_sql.' '.$where.'  '.$sql;
    } else {
            $query = '
                   SELECT SQL_CALC_FOUND_ROWS salemods.name sname,
                   salemods.id sid,
                   salemods.alias salias,
                   salemods.Description sdescription,
                   salemods.price sprice,
                   salemods.GalleryName sGalleryName,
                   salemods.idImage sidImage,
                   salemods.baseId sbaseId,
                   salemods.garanty sgaranty,
                   salemods.rating rating,
                   salemods.mpn mpn,
                   brands.name bname,
                   brands.alias balias
                   FROM salemods
                   INNER JOIN brands  ON brands.id = salemods.idBrand
                   WHERE salemods.idCategory = ? '.$price_sql.' '.$sql.' LIMIT '.$pager->getOffset().','.$pager->getLimit();
    }

   warn $query;

    my $sth = $db->prepare($query);
    $sth->execute($category->{id});

    while (my $item = $sth->fetchrow_hashref){
        push @buffer,$item;
    }

    my $csth = $db->prepare("select FOUND_ROWS()");
    $csth->execute();
    my ($scount) = $csth->fetchrow_array();

    $pager->setMax($scount);


    my @filters_set = ();
    my @filters_unset = ();
    my $filters_unset_brands;

    if (not $cfg->{disable_filters_mask} and $filter_mask_query){
        $db->do("create temporary table filters_mask$$ (idSalemod int, UNIQUE KEY `idSalemod` (`idSalemod`)) ENGINE=Aria");
        my $sth = $db->prepare($filter_mask_query);
        $sth->execute($category->{id});
        $filters->set_mask_table_name("filters_mask$$");
        @filters_set = $filters->get_set();
        @filters_unset = $filters->get_unset();
        $filters_unset_brands = $filters->get_unset_brands();
        $db->do("drop table if exists filters_mask$$");
    } else {
        @filters_set = $filters->get_set();
        @filters_unset = $filters->get_unset();
    }


    get_template(
        "frontoffice/templates/sales" => $r,
        category => $category,
        brand => $a->{brand},
        sales => \@buffer,
        a => $a,
        temp => $temp,
        pager => $pager,
        look => 'child',
        session_values => $sort,
        res_count => $scount,
        filters_set => \@filters_set,
        filters_unset => \@filters_unset,
        filters_unset_brands => $filters_unset_brands,
        request_uri => $r->uri,
        filer_minprice => $minprice,
        filer_maxprice => $maxprice,
    );
    return OK;
}

sub main_sales_paged(){
    my $category     = shift;
    my $subcategory  = shift;
    my $page         = shift;

    if($page eq '1'){
	   &main_redirect_301('/'.$category.'/'.$subcategory.'.html');
    }
    &main_sales({  category => $category,  subcategory => $subcategory,  page => $page  });
}


sub main_sales_nonpaged(){
    &main_sales({
	    category => shift,
	    subcategory => shift,
	    first_page => 1,
	    page => '1',
	    pagecount => '124',
	    });
}

sub main_sales_brands(){
    my $category    = shift;
    my $subcategory = shift;
    my $brand       = shift;
    my $page        = shift;

    my $model = Model::Brand->load($brand,'alias');
    
    $brand =~ /^([0-9]{1,})_124/;
    
    if(exists $model->{alias}){

        &main_sales({
	       category => $category,
	       subcategory => $subcategory,
	       brand => $model,
	    });
    } 
    else {
        &main_sales({
            category => $category,
            subcategory => $subcategory,
            page => $1,
            pagecount => '124',
        });
    }

}

sub main_sales_brands_paged(){
    my $category    = shift;
    my $subcategory = shift;
    my $model       = Model::Brand->load(shift,'alias');
    my $page        = shift;
    my $pageocunt   = shift;

    if($page eq '1'){
	   &main_redirect_301('/'.$category.'/'.$subcategory.'/'.$model->{alias}.'.html');
    }


	&main_sales({
		category => $category,
		subcategory => $subcategory,
		brand => $model,
		page => $page,
	});



}


sub main_sales_brands_nonpaged(){
    my $category    = shift;
    my $subcategory = shift;
    my $brand       = shift;

    my $model       = Model::Brand->load($brand,'alias');

    &main_sales({
	    category       => $category,
	    subcategory    => $subcategory,
	    brand          => $model,
	});
}

sub main_sales_brands_show(){

    my $category    = shift;
    my $subcategory = shift;
    my $model       = Model::Brand->load(shift,'alias');
    my $show        = shift;

    &main_sales({
	    category       => $category,
	    subcategory    => $subcategory,
	    brand          => $model,
	    show           => $show,
    });
}

sub main_sales_brands_sort(){
    my $category = shift;
    my $subcategory = shift;
    my $model = Model::Brand->load(shift,'alias');
    my $sort = shift;

    &main_sales({
	    category => $category,
	    subcategory => $subcategory,
	    brand => $model,
	    sort => $sort,
    });
}

sub main_sales_brands_on_page(){
    my $category    = shift;
    my $subcategory = shift;
    my $model       = Model::Brand->load(shift,'alias');
    my $on_page     = shift;

    &main_sales({
	    category       => $category,
	    subcategory    => $subcategory,
	    brand          => $model,
	    on_page        => $on_page,
    });
}



sub main_sales_sort(){
    &main_sales({
	   category        => shift,
	   subcategory     => shift,
	   sort            => shift,
    });
}

sub main_sales_on_page(){
    &main_sales({
    	category       => shift,
    	subcategory    => shift,
    	on_page        => shift,
    });
}



sub main_sales_show(){
    &main_sales({
    	category       => shift,
    	subcategory    => shift,
    	show           => shift,
    });
}

sub main_sales_filter_brand(){

     my $category       = shift;
     my $subcategory    = shift;
     my $value          = shift;
     my $brand          = Model::Brand->load($value,'alias');


     my $call = Core::Propertys->main_sales_filter_action({
       category    => $category,
       subcategory => $subcategory,
       id          => $brand->{id},
       value       => $value,
       action      => 'addbrand',
       sort        => '',
       limit       => '',
    });

    &main_sales({
	    category       => $category,
	    subcategory    => $subcategory,
	    first_page     => 0,
    });
}



sub main_comments(){
    return undef unless $args->{'tables'};
    my $salemod = Model::SaleMod->load($args->{'idMod'}) if $args->{'tables'} eq 'salemods';
    my $page = Model::APRPages->load($args->{'idMod'}) if $args->{'tables'} eq 'apr_pages';
    my $com = $args->{comment};
    my $usr = $args->{name};
    $usr =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    $com =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

    $args->{name} = $usr;

    my $comment = Model::Comment->new($args);
    $comment->{idCategory} = $salemod->{idCategory} if $args->{'tables'} eq 'salemods';
    $comment->{idBrand} = $salemod->{idBrand} if $args->{'tables'} eq 'salemods';
    $comment->{idCategory} = $page->{idCategory} if $args->{'tables'} eq 'apr_pages';

    $comment->save_text($com);
    $comment->save();
    return &main_salemod($args->{alias},'comment') if $args->{'tables'} eq 'salemods';

    if ($args->{'tables'} eq 'parasite'){

        my $buf;

        $buf->{'phone'}     = $args->{'phone'};
		$buf->{'subject'}   = "recall me";

        my $office          = Core->office();
        $buf->{'to'}        = $office->{'email'};

        Sendmail('parasite',$buf);
    }

    return OK;
}
############### compare

sub main_comparison_clean(){
    Core::Comparison->clean();
    return OK;
}

sub main_comparison_clean_active(){
    Core::Comparison->clean();
    &main_index();
}

sub main_add_prod_to_comparison(){
   my $mod = Model::SaleMod->load( shift )               or return NOT_FOUND;

   Core::Comparison->add_prod_to_compare( $mod->{'id'} ) or return NOT_FOUND;

   get_template('frontoffice/templates/blocks/compare' => $r );

   return OK;
}

sub main_adel_prod_from_comparison(){
   my $id = shift;
   my $SaleMod = Model::SaleMod->load($id);

   Core::Comparison->del_prod_from_compare($SaleMod->{'id'});
   get_template(
   'frontoffice/templates/blocks/compare' => $r
   );

   return OK;
}

sub main_del_prod_from_comparison(){
    my $id = shift;
    my $SaleMod = Model::SaleMod->load($id);
    Core::Comparison->del_prod_from_compare($SaleMod->{'id'});
    &main_compare();
}

sub main_compare(){
    my $comprod = $s->get('comparison');
    my @salemods =();

    foreach (@{$comprod->{'prod'}}){

        push @salemods,{
            id => $_,
            model => Model::SaleMod->load($_),
            featureGroups => Core::Comparison->get_category_feature($comprod->{'cat'})
        };

    }
    foreach my $mod (@salemods){

        foreach my $featureGroup (@{$mod->{featureGroups}}){
            foreach my $feature (@{$featureGroup->{childs}}){
                $feature->{value} = $mod->{model}->get_features_value($feature->{id});
            }
        }

    }

    if (@salemods == 0){

        get_template(
            'frontoffice/templates/compare' => $r,
            'look' => 'empty',
        );

    }
    else {

        get_template(
            'frontoffice/templates/compare' => $r,
            'look' => 'compare',
            'featureGroups' => Core::Comparison->get_category_feature($comprod->{'cat'}),
            'salemods' => \@salemods,
            'category' => Model::Category->load($comprod->{'cat'}),
        );
    }

    return OK;
}

sub main_salemods_next_slide(){
        my $smod = Model::SaleMod->load( $args->{'idMod'} );

        get_template(
            'frontoffice/templates/blocks/slider_item' => $r,
            'list' => $smod->get_next_salemods(8),
        );

        return 'OK';
}

sub main_sendmail(){
	my  $buf->{'subject'} = 'test';
	my $office = Core->office();
	$buf->{'to'} = $office->{'email'};
	for my $key ( keys $args ) {
        	my $value = $args->{$key};
        	$buf->{text}.= "$key => $value <br>";
  	}
	Sendmail('text',$buf); #tekst - shablon v kotorom netu nichego - prosto text i pizdec
	return 'OK';
}
1;
