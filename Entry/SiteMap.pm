package Entry::SiteMap;


use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;

use Apache2::SubRequest;
use Apache2::RequestRec;

use Logger;
use DB;
use Tools;
use Core::Template  qw/get_template/;
use Tplc      qw/get_template_c/;
use Data::Dumper;
use Core::Session;
use Model::Category;
use Model::APRPages;
use Core::User;
use Cfg;

use Encode;
use Core::Meta;

our $r;
our $s;
our $user;
our $args;

my $ALIAS = " \\_ \\w \\d \\- \\+ \\( \\) \\: \\,";

sub handler(){
    our $r = shift;
    $r->content_type('text/html');

    our $args = &Tools::get_request_params($r);

    our $s = Core::Session->instance(1);
    our $user = Core::User->current();

    Core::Meta->instance(1,$req); #sadefault url

    my %content = (
	    "\\/sitemap\\/list\\.html" => *sitemap_list{CODE},
	    "\\/sitemap\\/list_tss\\.htm" => *sitemap_list_tss{CODE},       
        "\\/sitemap\\/ctpp\\.([htm|json]+)" => *ctpp{CODE},
	    "\\/sitemap\\/brands_list\\.html" => *sitemap_brands_list{CODE},
	    "\\/sitemap\\/brand\\/([$ALIAS]+)\\.html"  => *sitemap_brands_list_cat{CODE},
	    );

		foreach my $reg (keys %content){
			if (my @args = ($r->uri() =~ /^$reg$/)){
				return &{$content{$reg}}(@args);
				return $r if $r;
			}
		}
        &not_found($req);

#    return NOT_FOUND;
}


sub redirect($){
    my $href = shift;
    $s->save();
    $r->method('GET');
    $r->method_number(M_GET);
    $r->internal_redirect_handler($href);
    exit;
}

sub not_found(){
    return NOT_FOUND;
}

sub res(){ 
    my $res;
    
    if($args->{m} and $args->{a}){      
    


        my $t2m = {
            'category'             => 'Model::Category',
            'brands'               => 'Model::Brand',
            'salemods'             => 'Model::SaleMod',
            'new_orders'           => 'Model::NewOrders',
            'new_orders_positions' => 'Model::NewOrdersPositions',
            'currency'             => 'Model::Currency',
            'office'               => 'Model::Office',
            'saler'                => 'Model::Saler',
            'gallery'              => 'Core::Gallery::Image',
            'banner_product_types' => 'Model::BannerProductTypes',
            'features'             => 'Model::Feature',
            'features_groups'      => 'Model::FeatureGroup',
            'currency'             => 'Model::Currency',
            'salerprices'          => 'Model::SalerPrices',
            'meta'                 => 'Model::Meta',
            'meta'                 => 'Model::Meta',
            'bannerproductypes'    => 'Model::BannerProductTypes',
            'bannerproducts'       => 'Model::BannerProducts',
        };

        my $m = $t2m->{ $args->{m} };
        no strict 'refs'; 
        eval {"use $m;"};  
        use strict;

        if ( $args->{a} eq 'list' )         { $res = $m->list();                                                }
        if ( $args->{a} eq 'new' )          { $res = $m->load($args);                                           }
        if ( $args->{a} eq 'load' )         { $res = $m->load( $args->{id} );                                   }
        if ( $args->{a} eq 'post' )         { my $mm = $m->new($args); $mm->save(); $res = $mm; undef $mm       }
        if ( $args->{a} eq 'list_where' )   { $res = $m->list_where( $args->{ $args->{col} }, $args->{col} );   }

        undef $m; undef $t2m;
    }
    return $res;
}

sub ctpp(){     
    get_template_c(
        'index_'.$_[0]  => $r, 
         a              => $args,
         item           => &res(),
         url            => '/sitemap/ctpp',
         format         => $_[0],
    );
    return OK;
}

sub sitemap_list_tss(){
    my $self = shift;
    my $res = `/usr/bin/perl /var/www/globalmusic.com.ua/bin/crond.plx Import1C`;
    get_template('frontoffice/templates/sitemap/tss' => $r, 'res' => $res);
    return OK;
}
sub sitemap_list(){
    my $self = shift;
    get_template('frontoffice/templates/sitemap' => $r, 'look' => 'categories',);
    return OK;
}
sub sitemap_brands_list(){
    my $self = shift;
    get_template('frontoffice/templates/sitemap' => $r, 'look' => 'brands',);
    return OK;
}
sub sitemap_brands_list_cat(){
    my $alias = shift;
    use Model::Brand;
    my $mod = Model::Brand->load($alias,'alias') or return NOT_FOUND;
    Core::Meta->instance->change($mod,'brandcats');

    get_template(
	    'frontoffice/templates/brands' => $r,
	  	  brand  => $mod,
	  	  temp  => 'cat_list',
	    );
    return OK;
}

1;
