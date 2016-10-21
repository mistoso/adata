package Entry::Content;


use locale;
use POSIX qw(locale_h);
setlocale(LC_CTYPE,"ru_UA.UTF-8");

use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;

use Apache2::SubRequest;
use Apache2::RequestRec;

use Logger;
use DB;
use Tools;
use Core::Template qw/get_template/;
use Data::Dumper;
use Core::Session;
use Core::User;
use Cfg;
use Encode;
use Core::Meta;
use Model::Content::Task;
use Model::Content::User;

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
    # For Benchmark
    #--------------------------------------------------------------------------------------------
    our $params_string = '';
    map { $params_string .= $_."=".$args->{$_}."&" } keys %{$args};
    our $s = Core::Session->instance(1);
    our $user = Model::Content::User->current();
    #--------------------------------------------------------------------------------------------
    # META tags control
    #--------------------------------------------------------------------------------------------
    Core::Meta->instance(1,$req); #sadefault url
    #--------------------------------------------------------------------------------------------
    

    my $manage = $args->{manage} || '';
    my $action = $args->{action} || '';
    my $show = $args->{show} || '';
    my $wmsg= "Processing, manage=$manage, action=$action , show=$show, user=$user->{name}";

    if ($r->prev){
        $wmsg .= " has prev request \n";
    }else{
        $wmsg .= " no prev request\n $r->args() $params_string";
    }
    return FORBIDDEN if $user->{'active'} eq 0;
    return &{"content_$manage"} if $manage and not $action and not $show;
    return &{"content_${manage}_$action"} if $manage and $action and not $show;
    return &{"content_${manage}_${action}_$show"} if $manage and $action and $show;

    return OK;
}


sub redirect($){
        my $href = shift;
        $s->save();
        $r->method('GET');
        $r->method_number(M_GET);
        $r->internal_redirect_handler($href);
	exit;
}

sub content_menu {
    
    get_template(
            'content/templates/menu' => $r,
            'cuser' => $user,
        );
    
    return OK; 
}

sub content_new {

    get_template(
        'content/templates/list' => $r,
        'list' => $user->newTask(),
        'state' => 'new',
    );
    
    return OK; 
}

sub content_done {

    get_template(
        'content/templates/list' => $r,
        'list' => $user->doneTask(),
        'state' => 'done',
    );
    return OK; 
}

sub content_rejected {

    get_template(
        'content/templates/list' => $r,
        'list' => $user->rejectedTask(),
        'state' => 'reject',
    );
    return OK; 
}

sub content_show {

    get_template(
        'content/templates/showtask' => $r,
        'task' => Model::Content::Task->load($args->{'id'}),
    );
    return OK; 
}

sub content_image {

    my $task = Model::Content::Task->load($args->{'id'});
    my $fh = &Tools::get_multipart_request_param_fname($r,'file');

    $task->product->add_image($fh);

    $r->headers_out->set(Location => $r->headers_in->{Referer});
    return REDIRECT;
}

sub content_image_delete {

    my $task = Model::Content::Task->load($args->{'id'});

    $task->product->delete_image($args->{image_id});

    $r->headers_out->set(Location => $r->headers_in->{Referer});
    return REDIRECT;
}

sub content_post {
    
    my $task = Model::Content::Task->load($args->{'id'});

    $task->product->{Description}     = $args->{Description};
    $task->product->{name}     = $args->{name};
    $task->product->{DescriptionFull} = $args->{DescriptionFull};
    $task->product->save();

    $task->{state} = 'done';
    $task->save();

    $r->headers_out->set(Location => $r->headers_in->{Referer});
    return REDIRECT;
}

sub content_statistic() {
     
    get_template(
        'content/templates/statistic' => $r,
        'statistic' => $user->statistic(),
    );
    return OK; 
}


#sub content_features_change_select(){
#    foreach my $key (keys %$args){
#	my ( $ident, $idFeature ) = split(/_/,$key);
#	if($ident eq 'feature' && $args->{idMod} && $idFeature ){
#	    my $sth = $db->prepare("replace content_features set idSaleMod = ?, idFeatureGroup = ?, value = ?");
#	    $sth->execute($args->{idMod},$idFeature,$args->{$key});
#	}
#    }
#    redirect('/cgi-bin/contentadmin?manage=show&id='.$args->{id});
#}


sub content_salemod_features_post {
                          
    $features = ();
    foreach (keys %{$args}) {
        if (/^feature_(\d+)/) {
            $features->{$1} = $args->{$_};
        }
    }

    my $sth = $db->prepare("replace into content_features(idSaleMod,idFeatureGroup,value) values(?,?,?)");
    foreach my $key (keys %{$features}) {
	if($features->{$key}){
    	    $sth->execute($args->{id},$key,$features->{$key});
    	}
    }

    &content_salemod_features();
}


sub content_salemod_features {

    use Model::FeatureGroups;
    use Model::Feature;

    my $salemod = Model::SaleMod->load($args->{id});
    my $feature_groups = Model::FeatureGroups->list_active_main($salemod->{idCategory});

    my $sth = $db->prepare("select distinct(f.value) from content_features f inner join feature_groups g on g.id = f.idFeatureGroup where g.type = 'string' and g.idCategory = ?");
    $sth->execute($salemod->{idCategory});
    
    my @autocomplite = ();
    while ( my ($value) = $sth->fetchrow_array()) {
        push @autocomplite,$value;
    }

    my $sth = $db->prepare("select id,idFeatureGroup,value from content_features where idSalemod = ? ");
    $sth->execute($salemod->{id});
    
    my $features = ();
    while (my $item = $sth->fetchrow_hashref) {
        $features->{$item->{idFeatureGroup}} = $item;
    }

    get_template(
	'content/templates/edit_features' => $r,
        'feature_groups' => $feature_groups,
        'autocomplite' => \@autocomplite,
        'model' => $salemod,
        'features' => $features,
        'salemod_id' => $args->{id},
	    );
    return OK;
}
1;
