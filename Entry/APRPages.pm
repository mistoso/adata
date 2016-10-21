package Entry::APRPages;
use strict;
use warnings;
use locale;
use POSIX qw(locale_h);
#setlocale(LC_CTYPE,"ru_UA.UTF-8");
use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET HTTP_MOVED_PERMANENTLY/;
use Apache2::SubRequest;
use Apache2::RequestRec;
use Core;
use Logger;
use DB;
use Tools;
use Core::Template qw/get_template/;
use Core::Session;
use Model::Category;
use Model::APRPages;
use Core::User;
#use Cfg;
use Core::Error;
use Core::Mail;
use Clean;
use Core::Meta;


our $r;
our $s;
our $user;
our $args;

my $ALIAS = "\\w \\d \\- \\+ \\( \\) \\_";

sub handler(){
    $r = shift;
    my $req = $r->uri();
    $r->content_type('text/html');
    $args = &Tools::get_request_params($r);
    our $params_string = '';
    map { $params_string .= $_."=".$args->{$_}."&" } keys %{$args};
    $s = Core::Session->instance(1);
    $user = Core::User->current();
    Core::Meta->instance(1,$req);
    my %content = (
                "\\/info\\/([$ALIAS]+)\\.htm" => *apr_pages_type{CODE},
                "\\/info\\/([$ALIAS]+)\\/([$ALIAS]+)\\/limit_([$ALIAS]+)_([$ALIAS]+).html" => *apr_pages_section_paged{CODE},
                "\\/info\\/([$ALIAS]+)\\/([$ALIAS]+).htm" => *apr_pages_section{CODE},
                "\\/info\\/([$ALIAS]+)\\.html"  => *apr_pages_page{CODE},
	);
    map { $args->{$_} = Clean->all($args->{$_}) } keys %{$args};
    foreach my $reg (keys %content){
        if (my @args = ($req =~ /^$reg$/)){
            return &{$content{$reg}}(@args);
            return $r if $r;
        }
    }
    return &not_found($req);
    return NOT_FOUND;

}

sub redirect($);
sub redirect($){
    my $href = shift;
    $r->method('GET');
    $r->method_number(M_GET);
    $r->internal_redirect($href);
}
sub not_found(){
    return NOT_FOUND;
}
sub main_301(){
	my $lfr = shift;
	my $sth = $db->prepare('select lto from page_redirect where lfr = ? and deleted = 0;');
	$sth->execute($lfr);
	my $item = $sth->fetchrow_hashref;
	if($item->{lto}){
	    $r->no_cache(1);
	    $r->status(Apache2::Const::HTTP_MOVED_PERMANENTLY);
	    $r->headers_out->add(Location => $item->{lto});
	}else{
	    return 1;
	}
}
sub main_redirect(){
	&main_301($r->uri());
}
sub main_redirect_301(){
	my $url = shift;

	$r->no_cache(1);
	$r->status(Apache2::Const::HTTP_MOVED_PERMANENTLY);
	$r->headers_out->add(Location => $url);
}
sub apr_pages_type(){
    my $alias = shift;

	my $type  = Model::APRTypes->load($alias,'alias');
	Core::Meta->instance->change($type,'aprtype');

	get_template(
	    'frontoffice/templates/apr_pages' => $r,
	    type => $type,
	    temp => 'type',
	    );
	return OK;
}

sub apr_pages_section(){
    my $type_alias = shift;
    my $section_alias = shift;
    my $section  = Model::APRSections->load($section_alias,'alias');
    Core::Meta->instance->change($section,'aprsection');

    get_template(
	    'frontoffice/templates/apr_pages' => $r,
	    section => $section->front_pages(),
	    temp => 'section',
	    );
    return OK;
}
sub apr_pages_section_paged(){
    my $type_alias    = shift;
    my $section_alias = shift;
    my $limit_1       = shift;
    my $limit_2       = shift;

    my $limit = $limit_1.','.$limit_2;

    my $section  = Model::APRSections->load($section_alias,'alias');
    get_template(
	  'frontoffice/templates/apr_pages' => $r,
	  	  section 	=> 	$section->front_pages($limit),
	  	  limit 	=> $limit_1,
	  	  temp 		=> 'section',
	);
    return OK;
}

sub apr_pages_page(){
    my $page_alias = shift;
	my $page  = Model::APRPages->load($page_alias,'alias')
        or return &not_found();
    Core::Meta->instance->change($page,'aprpage');
    get_template(
	    'frontoffice/templates/apr_pages' => $r,
	    itm => $page,
	    temp => 'page',
	    );
	return OK;
}

1;

