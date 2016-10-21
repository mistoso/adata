package Entry::Import;

use 5.010; 
use warnings; 
use strict;         
use Apache2::SubRequest; 
use Apache2::Const qw/OK NOT_FOUND FORBIDDEN M_GET/;
use Core::Template qw/get_template/;
use Logger;     
use Core::Session;
use Core::User;
use Cfg;
use Base::Translate;
use Data::Dumper;

our( $r, $a, $s, $u, $q, $t2i );

$u = Core::User->current();
$s = Core::Session->instance(1);

sub handler {
    $r = shift; 
    $a = &Tools::get_request_params($r);  
	$q = $r->uri(); 
    $r->content_type('text/html');    
    return FORBIDDEN  unless $u;

    return &{"imp_".$a->{manage}}                     
        if  exists      $a->{manage}        
        and not exists  $a->{action} 
        and not exists  $a->{show};  

    return &{"imp_".$a->{manage}."_".$a->{action} }   
        if  exists      $a->{manage} 
        and exists      $a->{action}        
        and not exists  $a->{show};  

    return &{"imp_".$a->{manage}."_".$a->{action}."_".$a->{show} }   
        if  exists      $a->{manage} 
        and exists      $a->{action} 
        and exists      $a->{show};

    return OK;
}
    
sub redirect($); 
sub hredirect($$);

use Import::Model::Products;
use Import::Model::Categories; 
use Import::Model::CatProperties;
use Import::Model::Dictionary;

$t2i = { 
    'users'             => 'Core::User', 
    'categories'        => 'Import::Model::Categories',
    'products'          => 'Import::Model::Products',
    'cat_properties'    => 'Import::Model::CatProperties',
    'dictionary'        => 'Import::Model::Dictionary',
};

sub imp_common() {
    my ( $cn, $fn ) = ( $t2i->{ $a->{m} }, $a->{a} );
    get_template( 
      'backoffice/templates/st/common/'.$a->{t} => $r, 
      itm => $cn->$fn() 
    );    
    return OK; 
}
sub imp_common_list() {
    my $cn = $t2i->{ $a->{m} }; 
    get_template( 
      'backoffice/templates/st/common/'.$a->{t} => $r,
      itm => $cn->list() 
    ); 
    return OK; 
}
sub imp_common_load() {
    my $cn = $t2i->{ $a->{m} }; 
    get_template(
      'backoffice/templates/st/common/'.$a->{t} => $r, 
      itm => $cn->load( $a->{id} ) 
    ); 
    return OK; 
}
sub imp_categories_list() {
  get_template( 
    'backoffice/templates/st/categories/list' => $r, 
     itm => Import::Model::Categories->list() 
  );
  return OK; 
}
sub imp_categories_products() { 
  my $m = Import::Model::Categories->load( $a->{id} )  or return NOT_FOUND; 
  get_template( 'backoffice/templates/st/categories/'.$a->{template} => $r, items => $m ); 
  return OK; 
}
sub imp_cat_properties_edit() { 
  my $m = Import::Model::CatProperties->load($a->{id}) or return NOT_FOUND; 
  get_template( 'backoffice/templates/st/categories/'.$a->{template} => $r, item  => $m ); 
  return OK; 
}

sub imp_categories_edit() {
  my $m = Import::Model::Categories->load($a->{id}) or return NOT_FOUND; 
  get_template( 'backoffice/templates/st/categories/'.$a->{template} => $r, item  => $m ); 
  return OK;
}

sub imp_products_edit() { 
  my $m = Import::Model::Products->load($a->{id}) or return NOT_FOUND; 
  get_template( 'backoffice/templates/st/products/'.$a->{template}   => $r, item  => $m ); 
  return OK;
}

sub imp_products_post() { 
  my $m = Import::Model::Products->new($a);  $m->save(); 
  redirect( '/cgi-bin/marketadmin?manage=products&action=edit&id='.$m->{id} ); 
}

sub imp_categories_post()     {
  my $m = Import::Model::Categories->new($a); $m->save(); 
  redirect( '/cgi-bin/marketadmin?manage=categories&action=edit&id='.$m->{id} ); 
}
sub imp_categories_cat_properties_list() { 
  my $m = Import::Model::Categories->load( $a->{pro_cat_id} ) or return NOT_FOUND; 
  get_template( 'backoffice/templates/st/categories/list' => $r, items => $m ); 
  return OK;
}

sub imp_excategory() 		{ get_template( 'backoffice/templates/st/excategory/tree' => $r ); return OK;}
sub imp_excategory_items() 	{ get_template( 'backoffice/templates/st/excategory/tree_items' => $r );  return OK; }

sub redirect($){ 
  my $href = shift; my $s = Core::Session->instance(); 
  $s->save(); $r->method('GET'); $r->method_number(M_GET); 
  $r->internal_redirect($href); 
}

######### stylus #########################################st

1;
