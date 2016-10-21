package Entry::Ajax;
use strict;
use warnings;


use locale;
use POSIX qw(locale_h);
setlocale(LC_CTYPE,"ru_UA.UTF-8");

use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;

use Apache2::SubRequest;
use Apache2::RequestRec;

use Logger;
use Core::DB;
use Tools;
use Core::Template qw/get_template/;
use Data::Dumper;
use Core::Session;
use Model::Category;
use Model::APRPages;
use Core::User;
use Cfg;                   
use Core::Error;
use Core::Mail;
use Core::Client::Form;

use Clean;
use Core::Meta;


our $r;
our $s;
our $user;
our $args;

my $ALIAS = "\\w \\d \\- \\+ \\( \\) \\_";

sub handler(){
    our $r = shift;
    my $req = $r->uri();
    $r->content_type('text/html');
    our $args = &Tools::get_request_params($r);

    our $params_string = '';
    map { $params_string .= $_."=".$args->{$_}."&" } keys %{$args};
    #--------------------------------------------------------------------------------------------
    
    $s = Core::Session->instance(1);
    
    our $user = Core::User->current();

    Core::Meta->instance(1,$req);

    my %content = (
                "\\/ajax\\/category_brand_salemods\\/(\\d+)_(\\d+)\\.html" => *ajax_category_brand_salemods{CODE},
                "\\/ajax\\/category_brand\\/(\\d+)\\.html" => *ajax_category_brand{CODE},
                "\\/ajax\\/check\\.html" => *ajax_check{CODE},


	);

    map { $args->{$_} = Clean->all($args->{$_}) } keys %{$args};

    foreach my $reg (keys %content){
        if (my @args = ($req =~ /^$reg$/)){
            return &{$content{$reg}}(@args);
            return $r if $r;
        }
    }	
    return NOT_FOUND;
}

sub redirect($);

sub redirect($){
    my $href = shift;
    $r->method('GET');
    $r->method_number(M_GET);
    $r->internal_redirect($href);
}

sub ajax_check(){
    return 'OK';
}


sub ajax_category_brand_salemods(){
    my $brand = shift;
    my $category = shift;
    my @buf;
    my $sth = $db->prepare("SELECT name as name, alias as alias from salemods where idBrand = ? AND idCategory = ? AND isPublic != 0 ORDER BY name;");
    $sth->execute($brand, $category);
    while (my $item = $sth->fetchrow_hashref){
	push @buf, $item;
    }
    get_template(
	'frontoffice/templates/ajax/select' => $r,
	temp => 'salemods',
	item => \@buf,
    );
    return OK;
}

sub ajax_category_brand(){
    my $category = shift;
    my @buf;

    my $sth = $db->prepare("SELECT b.id as bid, 
                                   b.name bname, 
                                   count(s.id) smcount,
                                   s.idCategory cid
                              FROM brands b INNER JOIN salemods s ON b.id = s.idBrand 
                             WHERE s.idCategory = ? 
                               AND s.isPublic != 0 
                          GROUP BY b.id 
                          ORDER BY b.name;");
    $sth->execute($category);
    while (my $item = $sth->fetchrow_hashref){
	push @buf, $item;
    }
    get_template(
	'frontoffice/templates/ajax/select' => $r,
	temp => 'category',
	item => \@buf,
    );
    return OK;
}

1;
