package Entry::Xml;
use strict;
use warnings;

use locale;
#use POSIX qw(locale_h);
#setlocale(LC_CTYPE,"ru_UA.UTF-8");

use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET HTTP_MOVED_PERMANENTLY/;
use Apache2::SubRequest;
use Apache2::RequestRec;
use Logger;
use Core::DB;
use Tools;
use Core::Template qw/get_template/;
use Core::Session;
use Core::User;
use Cfg;

use Core;

our $r;
our $s;
our $user;
our $args;

my $ALIAS = " \\_ \\w \\d \\- \\+ \\( \\) \\: \\,";

sub handler(){
    our $r = shift;

    my $req = $r->uri();
    $r->content_type('text/html');
    our $args = &Tools::get_request_params($r);

    #--------------------------------------------------------------------------------------------

    our $params_string = '';
    map { $params_string .= $_."=".$args->{$_}."&" } keys %{$args};
    #--------------------------------------------------------------------------------------------
    our $s = Core::Session->instance(1);
    our $user = Core::User->current();


    my %content = (
    	'\\/xml\\/test\\/'             => *xml_test{CODE},
        '\\/xml\\/category\\/'         => *xml_category{CODE},
    	'\\/xml\\/category_smotri\\/'  => *xml_category_smotri{CODE},
    	'\\/xml\\/category_tehno\\/'   => *xml_category_tehno{CODE},
    );
    
	foreach my $reg (keys %content){
	if (my @args = ($req =~ /^$reg$/)){
	return &{$content{$reg}}(@args);
	return $r if $r;
	}
    }	
    return &not_found($req);
    return NOT_FOUND;
}

sub redirect($){
        my $href = shift;
        $s->save();
        $r->method('GET');
        $r->method_number(M_GET);
        $r->internal_redirect_handler($href);
	exit;
}

sub not_found() {
    return NOT_FOUND;
}

sub xml_category(){
    $r->content_type('application/xhtml+xml');
    get_template(
	    'frontoffice/templates/xml/xml_category' => $r,
	    );
    return OK;
}

sub xml_test(){
    get_template(
	    'frontoffice/templates/xml/test' => $r,
	    );


    return OK;
}


sub xml_category_smotri(){
    $r->content_type('application/xhtml+xml');
    get_template(
	    'frontoffice/templates/xml/xml_category_smotri' => $r,
	    );
    return OK;
}

sub xml_category_tehno(){
    $r->content_type('application/xhtml+xml');
    get_template(
	    'frontoffice/templates/xml/xml_category_tehno' => $r,
	    );
    return OK;
}

#sub main_category(){
#    my $alias = shift;
#    my @buf;
#    my $sth = $db->prepare("");
#    $sth->execute($alias);
#    while (my $item = $sth->fetchrow_hashref){
#	push @buf, $item;
#    }
#    get_template(
#	    'frontoffice/templates/category' => $r,
#	    'category' => $category,
#	    );
#    return OK;
#}

1;
