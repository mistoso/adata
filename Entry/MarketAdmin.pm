package Entry::MarketAdmin;

use strict;

use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;
use Core::Template qw/get_template/;
use Apache2::SubRequest;

use Core;
use Core::Pager;
use Core::PriceUpdate;
use Core::Session;
use Cfg;
use Logger;
use DB;
use Core::User;
use Core::Find;
use Core::Xls;
use Core::File;

use Model::Category;
use Model::NewOrders;
use Model::NewOrdersPositions;
use Model::Cloud;

use Model::PageRedirect;
use Model::SaleMod;
use Model::Currency;
use Model::Catalog;
use Model::Office;
use Model::Saler;
use Model::Video;
use Model::SubPrice;
use Model::Meta;
use Model::Meta::Url;
use Model::Category;
use Model::Brand;
use Model::Competitor;
use Model::NewOrders;
use Model::NewOrdersPositions;

use Base::StTemplate;
use Base::Translate;
use Data::Dumper;

our ( $r, $args, $user, $import );

our $t = 'backoffice/templates/';

our $MSG_CODES  = {};
our $type2model = {
    'category'             => 'Model::Category',
    'brands'               => 'Model::Brand',
    'salemods'             => 'Model::SaleMod',
    'new_orders'           => 'Model::NewOrders',
    'new_orders_positions' => 'Model::NewOrdersPositions',
    'currency'             => 'Model::Currency',
    'office'               => 'Model::Office',
    'gallery'              => 'Core::Gallery::Image',
    'banner_product_types' => 'Model::BannerProductTypes'
};

####   ####
sub handler {
    $r    = shift;
    $args = &Tools::get_request_params($r);
    my $s = Core::Session->instance(1);
    $user = Core::User->current() or return NOT_FOUND;


    return FORBIDDEN unless $user;

    my $manage  = $args->{manage} || '';
    my $action  = $args->{action} || '';
    my $show    = $args->{show}   || '';
    my $args_id = $args->{id}     || 0;

    Core::File->logs( '/var/log/www/users.log',
              ""
            . $cfg->{'temp'}->{'host'} . "\t"
            . $user->{name} . "\t"
            . $manage . "\t"
            . $action
            . "\t$args_id\n" );

    no strict 'refs';

    if (   ( $manage eq 'priceimport' )
        || ( $manage eq 'salers' )
        || ( $manage eq 'catalog' )
        || ( $manage eq 'comments' ) )
    {
        return FORBIDDEN unless $user->isInGroup( 'root', 'manager' );
    }

    elsif (( $manage eq 'apr_pages' )
        || ( $manage eq 'comments' )
        || ( $manage eq 'cat_page_salemods' ) )
    {
        return FORBIDDEN unless $user->isInGroup( 'content', 'root' );
    }

    elsif (( $manage eq 'usercat' )
        || ( $manage eq 'currency' )
        || ( $manage eq 'meta' )
        || ( $manage eq 'meta_url' )
        || ( $manage eq 'offices' )
        || ( $manage eq 'users' ) )
    {
        return FORBIDDEN unless $user->isInGroup('root');
    }
    else { }

    return &{"admin_$manage"} if $manage and not $action and not $show;
    return &{"admin_${manage}_$action"} if $manage and $action and not $show;
    return &{"admin_${manage}_${action}_$show"}
        if $manage
        and $action
        and $show;
    use strict;

    return OK;
}
####   ####

####   ####
sub redirect($);
sub hredirect($$);
sub redirect($) {
    my $href = shift;
    my $s    = Core::Session->instance();
    $s->save();
    $r->method('GET');
    $r->method_number(M_GET);
    $r->internal_redirect($href);
}

####   ####

sub admin_common() {
    my $m = $type2model->{ $args->{m} };

    no strict 'refs';
    eval {"use $m;"};
    use strict;

    if ( $args->{a} eq 'load' ) {
        &_view( 'load', $m->load( $args->{id} ) );
    }

    if ( $args->{a} eq 'list' ) {
        &_view( 'list', $m->list() );
    }

    if ( $args->{a} eq 'list_where' ) {
        &_view( 'list', $m->list_where( $args->{ $args->{col} }, $args->{col} ) );
    }

    if ( $args->{a} eq 'new' ) {
        &_view( 'load', $m->load($args) );
    }

    if ( $args->{a} eq 'post' ) {
        my $m = $m->new($args);
        &_view( 'load', $m->save() );
    }
}


our $tpl_cmn   = $t . 'common/';
our $tpl_jqw   = $t.'jqw/';

sub _view() {
    my $v = $args->{t} || shift ||  'index';

    $v = $args->{t} || 'index';

    get_template(
        $tpl_jqw . $v => $r,
        tpl         => $args->{m} . '/' . $_[0] . '.html',
        itm         => $_[1]
    );
    return OK;
}

####   ####
sub admin_guess {

    return undef unless $args->{id};
    get_template(
        'backoffice/templates/features/product/show_guess' => $r,
        'model' => Model::SaleMod->load( $args->{id} ),
    );
    return OK;
}

sub admin_run_script() {
    my @buf;
    my @script;
    @script = split( ' ', $args->{script} );

    #  if (-e "$args->{script}"){
    if ( -e "@script[0]" ) {
        @buf = Core->run_script( $args->{script} );
    }
    print @buf;
    return OK;
}

sub admin_crontab() {
    my $sth = $db->prepare("select * from crontab");
    $sth->execute();
    my @buf;
    while ( my $item = $sth->fetchrow_hashref ) {
        push @buf, $item;
    }
    get_template(
        'backoffice/templates/settings/crontab' => $r,
        'tab'                                   => \@buf,
    );
    return OK;
}

sub admin_outward_cod() {

    my $sth = $db->prepare("select * from outward_cod");
    $sth->execute();
    my @buf;
    while ( my $item = $sth->fetchrow_hashref ) {
        push @buf, $item;
    }
    get_template(
        'backoffice/templates/settings/outward_cod' => $r,
        'hosts'                                     => \@buf,
    );
    return OK;
}

sub admin_report_bottom() {
    get_template(
        'backoffice/templates/bottom-report' => $r,
        'currencys'                          => Model::Currency->list(),
    );
    return OK;
}
####  ####
sub admin_delete_duplicat_name() {
    my $sth
        = $db->prepare(
        "select name,count(name) as cnt from salemods group by name order by count(name) desc"
        );
    $sth->execute();

    while ( my $item = $sth->fetchrow_hashref() ) {
        unless ( $item->{cnt} eq '1' ) {
            my $i = 0;
            my $sm
                = $db->prepare( "select id from salemods where name = '"
                    . $item->{name}
                    . "' order by id asc " );
            $sm->execute();
            print $item->{name} . "---" . $item->{cnt} . "<br>";
            while ( my $item1 = $sm->fetchrow_hashref() ) {
                $i = $i + 1;
                next if $i == 1;
                my $sth = $db->prepare("delete from salemods where id = ?");
                $sth->execute( $item1->{'id'} );

            }
        }
    }

    return OK;
}

sub admin_delete_empty_tasks() {
    my $sth
        = $db->prepare(
        "update content_tasks t left outer join salemods s on t.idSaleMod = s.id set t.deleted = 1 where s.id is null"
        );
    $sth->execute();
    my $sth = $db->prepare("delete from content_tasks where deleted");
    $sth->execute();
    return OK;
}

sub admin_delete_empty_strings() {
    my $sth
        = $db->prepare(
        "update salerprices sp left outer join salemods s on sp.idsaleMod = s.id set ignored = 1 where s.id is null"
        );
    $sth->execute();
    my $sth
        = $db->prepare(
        "update salerprices sp left outer join salers s on s.id = sp.idSaler set ignored = 1 where s.id is null"
        );
    $sth->execute();
    my $sth = $db->prepare("delete from salerprices where ignored");
    $sth->execute();
    return OK;
}
####   ####
sub admin_sms() {
    get_template(
        'backoffice/templates/sms/form' => $r,
        'cfg'                           => $cfg->{SMS}
    );
    return OK;
}

sub admin_sms_req() {
    use Core::SMS;
    Core::SMS->send_sms_to_phone( $args->{mess}, $args->{phone} );
    return OK;
}

sub admin_css() {
    Core::File->replace( $cfg->{temp}->{css_file}, $args->{str} )
        if $args->{str};
        
    Core::File->replace( $cfg->{temp}->{css_file_start}, $args->{str_start} )
        if $args->{str_start};

    get_template(
        $t . 'cat_css' => $r,
        itm            => Core::File->read( $cfg->{temp}->{css_file} ),
        itm_start      => Core::File->read( $cfg->{temp}->{css_file_start} )
    );

    return OK;
}

sub admin_users() {
    return NOT_FOUND unless $args->{type};
    my $list = ModelList->new( 'Core::User', $args->{page}, 50 );
    $list->func("FIND_IN_SET('$args->{type}',type)");
    $list->order( 'lastName', 'firstName', 'name' );
    $list->load();
    get_template(
        'backoffice/templates/users/list' => $r,
        users                             => $list,
        usertype => Core::User::Type->load( $args->{type}, 'type' ),
    );
    return OK;
}

sub admin_usercat() {

    get_template(
        'backoffice/templates/users/categorys' => $r,

    );
    return OK;
}

sub admin_users_logs_list() {
    get_template(
        'backoffice/templates/users/logs' => $r,
        rows => Core::File->tail_logs( $cfg->{'temp'}->{'host'} )
    );
    return OK;
}
sub admin_efile() {
    use Array::Utils qw(:all);
    my @b = ();
    my @files;
    my $efile = $args->{efile};
    my $dir = '/var/www/' . $cfg->{temp}->{host} . '/html/frontoffice/templates/';

    chomp($efile);
    return NOT_FOUND if ( $efile =~ m/^[^a-zA-Z]/ );
    return NOT_FOUND unless Core::File->is( $dir . $efile );

    my @find = `find $dir |replace '$dir' '' |grep html`;

    foreach (@find) {
        chomp($_);
        next if m/different/;
        push @files, { name => $_ };
    }

    Core::File->replace( $dir . $efile, $args->{str} ) if $args->{str};

    get_template(
        $t . 'efile' => $r,
        files        => \@files,
        itm          => Core::File->read( $dir . $efile )
    );

    return OK;
}


sub admin_users_orders() {
    return NOT_FOUND unless $args->{id};
    get_template(
        'backoffice/templates/users/orders' => $r,
        muser => Core::User->load( $args->{id} ),
    );
    return OK;
}

sub admin_users_report() {
    return NOT_FOUND unless $args->{id};
    return FORBIDDEN
        unless $user->isInGroup('root')
        or $user->{id} == $args->{id};
    get_template(
        'backoffice/templates/users/report' => $r,
        muser => Core::User->load( $args->{id} ),
    );
    return OK;
}

sub admin_users_deliveryreport() {
    return NOT_FOUND unless $args->{id};
    return FORBIDDEN
        unless $user->isInGroup('root')
        or $user->{id} == $args->{id};
    get_template(
        'backoffice/templates/users/deliveryreport' => $r,
        muser => Core::User->load( $args->{id} ),
    );
    return OK;
}

sub admin_users_routesreport() {
    return NOT_FOUND unless $args->{id};
    get_template(
        'backoffice/templates/users/routesreport' => $r,
        muser => Core::User->load( $args->{id} ),
    );
    return OK;
}

sub admin_users_setgroup() {
    return OK unless $args->{id};
    $r->headers_out->set(
        Location => '/cgi-bin/marketadmin?manage=users&action=groups&id='
            . $args->{id} );
    my $user = Core::User->load( $args->{id} ) or return NOT_FOUND;

    my @buf;
    foreach my $key ( keys %$args ) {
        warn "PROCESSING $key with $args->{$key}...\n";
        next unless $key =~ /^t\d+$/;
        warn "GOOD\n";
        push @buf, $args->{$key};
    }
    unless (@buf) {
        return REDIRECT;
    }
    $user->{type} = join( ',', @buf );
    $user->save();
    return REDIRECT;
}

sub admin_users_groups() {
    return OK unless $args->{id};
    get_template(
        'backoffice/templates/users/groups' => $r,
        muser => Core::User->load( $args->{id} ),
    );

    return OK;
}

sub admin_users_post() {
    my $model = Core::User->new($args);
    if ( $args->{dbaction} eq 'insert' or $args->{dbaction} eq 'update' ) {
        if ( $model->save() ) {
        }
        else {
        }
    }
    elsif ( $args->{dbaction} eq 'delete' ) {
        $model->delete();
    }
    $r->headers_out->add( Location =>
            '/cgi-bin/marketadmin?manage=users&action=edit&reload=list&id='
            . $model->{id} );
    return REDIRECT;
}

sub admin_users_edit() {
    return NOT_FOUND unless $args->{id};
    my $user = Core::User->load( $args->{id} );
    return undef
        if ( ( $args->{id} eq '145957' ) || ( $args->{id} eq '145881' ) );
    get_template(
        'backoffice/templates/users/edit' => $r,
        muser                             => $user,
    );
    return OK;
}

sub admin_users_add() {

    get_template(
        'backoffice/templates/users/add' => $r,
        types                            => $user->types(),
    );
    return OK;
}

sub admin_users_show() {
    return NOT_FOUND unless $args->{id};

    my $user = Core::User->load( $args->{id} );

    get_template(
        'backoffice/templates/users/show' => $r,
        muser                             => $user,
    );

    return OK;
}

sub admin_users_delete() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/users/delete' => $r,
        muser => Core::User->load( $args->{id} ),
    );

    return OK;
}
####  ####
sub admin_new_orders() {
    get_template( 'backoffice/templates/new_orders/index' => $r, );
    return OK;
}

sub admin_new_orders_floor_price() {
    my $mod = Model::NewOrders->load($args->{'idOrder'});
    foreach(@{$mod->positions}) { $_->floor_price;  }
   
    redirect( "/cgi-bin/marketadmin?manage=new_orders&action=list&state=new" );
}

sub admin_new_orders_sold() {
    my $mod = Model::NewOrders->load($args->{'idOrder'});
    
    foreach(@{$mod->positions}) { $_->sold;  }
    $mod->{soldDate} = 'NOW()';
    $mod->save();
   
   
    redirect( "/cgi-bin/marketadmin?manage=new_orders&action=list&state=new" );
}



sub admin_new_orders_list() {

    my $res = Model::NewOrders->list_by_state(
        $args->{'state'}, 
        $args->{'orderby'},
        $args->{'desc'},  
        $args->{'limit'}
    );

    get_template(
        'backoffice/templates/new_orders/list' => $r,
        'list'                                 => \@{ $res->{'list'} },
        'state'                                => $args->{'state'},
        'orderby'                              => $args->{'orderby'},
        'desc'                                 => $args->{'desc'},
    );

    return OK;
}

sub admin_new_orders_post() {

    if ( $args->{'dbaction'} eq 'new' ) {
        my $order = Model::NewOrders->new();
        get_template(
            'backoffice/templates/new_orders/create_order' => $r,
            'order'                                        => $order,
        );
    }
    
    elsif ( $args->{'dbaction'} eq 'create' ) {
        my $order = Model::NewOrders->new($args);
        $order->{'currencyValue'} = Model::Currency->usd_currency();
        $order->{'created'}       = 'NOW()';
        $order->save;
        my $pos = Model::NewOrdersPositions->new();
        my $mod = Model::SaleMod->load( $args->{'idMod'} );
        $pos->{'idMod'}   = $mod->{'id'};
        $pos->{'state'}   = 'new';
        $pos->{'price'}   = $mod->{'price'};
        $pos->{'idOrder'} = $order->{'id'};
        $pos->save();
        redirect( "/cgi-bin/marketadmin?manage=new_orders&action=post&id="
                . $order->{id} );
    }
    
    elsif ( $args->{'dbaction'} eq 'edit' ) {
        get_template(
            'backoffice/templates/new_orders/edit_order' => $r,
            'order' => Model::NewOrders->load( $args->{'id'} ),
        );
    }
    elsif ( $args->{'dbaction'} eq 'save' ) {
        my $order = Model::NewOrders->new($args);
        $order->save();
        get_template(
            'backoffice/templates/new_orders/show_order' => $r,
            'order'                                      => $order,
        );
    }
    elsif ( $args->{'dbaction'} eq 'delete' ) {
        my $order = Model::NewOrders->load( $args->{'id'} );
        $order->del_positions();
        $order->delete();
    }
    else {
        get_template(
            'backoffice/templates/new_orders/show_order' => $r,
            'order'   => Model::NewOrders->load( $args->{'id'} ),
            'poz'     => $args->{'poz'},
            'history' => $args->{'history'},
        );
    }
    return OK;
}

sub admin_new_order_positions() {
    return undef unless $args->{'oid'};
    if ( $args->{'dbaction'} eq 'delete' ) {
        my $pos = Model::NewOrdersPositions->load( $args->{'id'} );
        $pos->{'deleted'} = 1;
        $pos->save();
        redirect( "/cgi-bin/marketadmin?manage=new_orders&action=post&id="
                . $args->{oid} );
    }
    elsif ( $args->{'dbaction'} eq 'insert' ) {
        my $pos = Model::NewOrdersPositions->new();
        $pos->{'state'} = 'new';
        my $mod = Model::SaleMod->load( $args->{'idMod'} );
        $pos->{'idMod'}   = $mod->{'id'};
        $pos->{'state'}   = 'new';
        $pos->{'price'}   = $mod->{'price'};
        $pos->{'idOrder'} = $args->{'oid'};
        $pos->save();
        redirect( "/cgi-bin/marketadmin?manage=new_orders&action=post&id="
                . $args->{oid} );

    }
    elsif ( $args->{'dbaction'} eq 'save' ) {
        my $pos = Model::NewOrdersPositions->new($args);
        $pos->save();
        if ( $args->{'state'} eq 'sold' ) { $pos->order_sold(); }
        redirect( "/cgi-bin/marketadmin?manage=new_orders&action=post&id="
                . $args->{oid} );
    }
    else {
        redirect( "/cgi-bin/marketadmin?manage=new_orders&action=post&poz="
                . $args->{id} . "&id="
                . $args->{oid} );
    }
    return OK;
}

sub admin_new_orders_print() {
    return undef unless $args->{'id'};
    get_template(
        'backoffice/templates/new_orders/ticket' => $r,
        'order' => Model::NewOrders->load( $args->{'id'} ),
    );
    return OK;
}

sub admin_no_stock_status() {
    if ( $args->{maketype} eq 'post' ) {
        Core->save_settings( 'no_stock_status', $args->{no_stock_status} );
    }
    get_template( 'backoffice/templates/settings/no_stock_status' => $r, );
    return OK;
}
####  ####
sub admin_page_redirect() {
    get_template(
        'backoffice/templates/redirect/list' => $r,
        'items'                              => Model::PageRedirect->list(),
    );
    return OK;
}

sub admin_page_redirect_post() {
    if ( !$args->{id} ) {
        my $model = Model::PageRedirect->new($args);
        $model->save();
    }
    if ( $args->{id} ) {
        my $sth = $db->prepare('delete from page_redirect where id = ?');
        $sth->execute( $args->{id} );
    }

    get_template(
        'backoffice/templates/redirect/list' => $r,
        'items'                              => Model::PageRedirect->list(),
    );
    return OK;
}
####  ####
sub admin_apr_pages_add_type() {
    get_template( 'backoffice/templates/apr/types_edit' => $r, );
    return OK;
}

sub admin_apr_pages_edit_type() {
    my $model = Model::APRTypes->load( $args->{id} );
    get_template(
        'backoffice/templates/apr/types_edit' => $r,
        item                                  => $model,
    );
    return OK;
}

sub admin_apr_pages_post_type() {
    my $model = Model::APRTypes->new($args);
    $model->save();
    redirect(
        '/cgi-bin/marketadmin?manage=apr_pages&action=edit_type&reload=1&id='
            . $model->{id} );
    return OK;
}

sub admin_apr_pages_delete_type() {
    return NOT_FOUND unless $args->{id};
    my $model = Model::APRTypes->load( $args->{id} ) or return NOT_FOUND;
    $model->delete();
    return OK;
}

sub admin_apr_pages_types_list() {
    get_template(
        'backoffice/templates/apr/types_list' => $r,
        list => Model::APRTypes->list_backoffice(),
    );
    return OK;
}

sub admin_apr_pages_sections_list() {
    my $model = Model::APRTypes->load( $args->{id} ) or return NOT_FOUND;
    get_template(
        'backoffice/templates/apr/sections_list' => $r,
        list                                     => $model,
    );
    return OK;
}

sub admin_apr_pages_add_section() {
    my $model = Model::APRTypes->list();
    get_template(
        'backoffice/templates/apr/sections_edit' => $r,
        types                                    => $model,
    );
    return OK;
}

sub admin_apr_pages_edit_section() {
    my $model = Model::APRSections->load( $args->{id} ) or return NOT_FOUND;
    get_template(
        'backoffice/templates/apr/sections_edit' => $r,
        section                                  => $model,
    );
    return OK;
}

sub admin_apr_pages_post_section() {
    my $model = Model::APRSections->new($args);
    $model->{updated} = 'NOW()';
    $model->save();
    redirect( '/cgi-bin/marketadmin?manage=apr_pages&action=edit_section&id='
            . $model->{id}
            . '&reload=1' );
    return OK;
}

sub admin_apr_pages_setimage_section() {
    return OK unless $args->{id};
    my $section = Model::APRSections->load( $args->{id} ) or return NOT_FOUND;
    $section->{idImage} = $args->{img};
    $section->save();
    redirect(
        '/cgi-bin/marketadmin?manage=apr_pages&action=gallery_section&reload=1&id='
            . $section->{id} );
    return OK;
}

sub admin_apr_pages_gallery_section() {
    return OK unless $args->{id};
    get_template(
        'backoffice/templates/apr/sections_gallery' => $r,
        section => Model::APRSections->load( $args->{id} ),
    );
    return OK;
}

sub admin_apr_pages_pages_list() {
    my $model = Model::APRSections->load( $args->{id} ) or return NOT_FOUND;
    get_template(
        'backoffice/templates/apr/pages_list' => $r,
        pages                                 => $model->pages(),
    );
    return OK;
}

sub admin_apr_pages_pages_list_paged() {
    my $model = Model::APRSections->load( $args->{id} ) or return NOT_FOUND;
    my $limit = $args->{limit1} . ',' . $args->{limit2};
    get_template(
        'backoffice/templates/apr/pages_list' => $r,
        pages                                 => $model->pages($limit),
    );
    return OK;
}

sub admin_apr_pages_add_page() {
    my $model = Model::APRTypes->load( $args->{type_id} );
    get_template(
        'backoffice/templates/apr/pages_edit' => $r,
        type                                  => $model,
    );
    return OK;
}

sub admin_apr_pages_edit_page() {
    my $model = Model::APRPages->load( $args->{id} ) or return NOT_FOUND;
    get_template(
        'backoffice/templates/apr/pages_edit' => $r,
        page                                  => $model,
        section => Model::APRSections->load( $model->{idCategory} ),
    );
    return OK;
}

sub admin_apr_pages_post_page() {
    my $model = Model::APRPages->new($args);
    my $date  = $args->{year} . "-" . $args->{month} . "-" . $args->{day};
    $model->{updated}   = 'NOW()';
    $model->{date_from} = $date;
    if ( $args->{year_to} && $args->{month_to} && $args->{day_to} ) {
        my $date_to
            = $args->{year_to} . "-"
            . $args->{month_to} . "-"
            . $args->{day_to};
        $model->{date_to} = $date_to;
    }
    $model->save();
    redirect( '/cgi-bin/marketadmin?manage=apr_pages&action=edit_page&id='
            . $model->{id}
            . '&reload=1' );
    return OK;
}

sub admin_apr_pages_post_page_list() {
    my $model = Model::APRPages->new($args) or return NOT_FOUND;
    $model->{updated} = 'NOW()';
    $model->save();
    redirect( '/cgi-bin/marketadmin?manage=apr_pages&action=pages_list&id='
            . $model->{idCategory} );
    return OK;
}

sub admin_apr_pages_setimage_page() {

    return OK unless $args->{id};

    my $page = Model::APRSPages->load( $args->{id} ) or return NOT_FOUND;
    $page->{idImage} = $args->{img};
    $page->save();

    redirect(
        '/cgi-bin/marketadmin?manage=apr_pages&action=gallery_page&reload&id='
            . $page->{id} );
    return OK;
}

sub admin_apr_pages_gallery_page() {
    return OK unless $args->{id};
    get_template(
        'backoffice/templates/apr/pages_gallery' => $r,
        page => Model::APRPages->load( $args->{id} ),
    );
    return OK;
}

sub admin_apr_pages_gallery_contact() {
    return OK unless $args->{id};
    get_template(
        'backoffice/templates/apr/contacs_gallery' => $r,
        'contact' => Model::APRContacts->load( $args->{id} ),
    );
    return OK;
}

sub admin_apr_pages_page_section() {
    foreach my $key ( keys %$args ) {
        my ($idPage) = ( $key =~ /^p(\d+)$/ );

        if ($idPage) {
            my ( $idSection, $from, $to )
                = ( $args->{$key} =~ /(.+);(.+);(.+)$/ );
            my $model = Model::APRPages->load($idPage);
            warn " lala -> $idSection, $from, $to";
            $model->update_page_section( $idSection, $from, $to );
        }
        next unless $idPage;
    }
}

sub admin_apr_pages_Csections_list() {
    my $model = Model::APRSections->load( $args->{id} ) or return NOT_FOUND;
    get_template(
        'backoffice/templates/apr/sections_contacts' => $r,
        section                                      => $model,
    );
    return OK;
}

sub admin_apr_pages_Cpages_list() {
    my $model = Model::APRPages->load( $args->{id} ) or return NOT_FOUND;
    get_template(
        'backoffice/templates/apr/pages_contacts' => $r,
        page                                      => $model,
    );
    return OK;
}

sub admin_apr_pages_post_contacts() {
    my $model = Model::APRContacts->new($args);
    $model->{updated} = 'NOW()';
    $model->save();

    if (   $model->{'idCategory'}
        && $model->{'idPage'}
        && !$model->{'by_url'}
        && !$model->{'idMod'} )
    {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=Cpages_list&id='
                . $model->{'idPage'} );
    }

    if (   $model->{'idMod'}
        && $model->{'idPage'}
        && !$model->{'by_url'}
        && !$model->{'idCategory'} )
    {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=Cpages_list&id='
                . $model->{'idPage'} );
    }

    if ( $model->{by_url} && $model->{idPage} && !$model->{idMod} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=Cpages_list&id='
                . $model->{idPage} );
    }
    if ( !$model->{idMod} && !$model->{idPage} && !$model->{by_url} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=Csections_list&id='
                . $model->{idSection} );
    }

    return OK;
}

sub admin_apr_pages_post_type_settings() {
    my $model = Model::APRTypesSettings->new($args);
    $model->save();
    redirect( '/cgi-bin/marketadmin?manage=apr_pages&action=edit_type&id='
            . $model->{idType} );
    return OK;
}

sub admin_apr_search() {
    my $cat     = Model::Category->load( $args->{'id'} );
    my $frase   = $args->{'frase'} || $cat->{'Description'};
    my $section = $args->{'section'} || 0;
    my $limit   = 10;
    my @buf;
    #################################
    my $srch = Core::Find->new();
    $srch->{'frase'} = $frase;
    $srch->search_apr( $section, $limit );
    foreach ( @{ $srch->{'ids'} } ) {
        push @buf, Model::APRPages->load($_);
    }
    #################################
    get_template(
        'backoffice/templates/category/apr_search' => $r,
        'list'                                     => \@buf,
        'cat'                                      => $cat,
    );
    return OK;
}
####  ####
sub admin_catalog_list() {
    get_template(
        'backoffice/templates/catalog/catalog_list' => $r,
        list                                        => Model::Catalog->list(),
    );
    return OK;
}

sub admin_catalog_set_sub_date_catalog() {
    my $sth = $db->prepare(
        "update catalogCategory set subDate = ? where idCatalog = ? ");
    $sth->execute( $args->{sub_date}, $args->{idCatalog} );
    redirect(
        '/cgi-bin/marketadmin?manage=catalog&action=category_list_d&idCatalog='
            . $args->{idCatalog} );
}

sub admin_catalog_set_ext_price_catalog() {
    my $sth = $db->prepare(
        "update catalogCategory set extprice = ? where idCatalog = ? ");
    $sth->execute( $args->{xextprice}, $args->{idCatalog} );
    redirect(
        '/cgi-bin/marketadmin?manage=catalog&action=category_list_p&idCatalog='
            . $args->{idCatalog} );
}

sub admin_catalog_post_price() {
    return NOT_FOUND unless $args->{id};
    my $model = Model::SaleMod->load( $args->{id} );
    if ( $args->{price} > 0 ) {
        $model->{price} = $args->{price};
        $model->save();
    }
    redirect(
        '/cgi-bin/marketadmin?manage=catalog&action=edit_contact&idCatalog='
            . $args->{idCatalog}
            . '&idMod='
            . $args->{id} );
}

sub admin_catalog_set_ext_price() {
    my $idCatalog;
    my $i;
    foreach my $key ( keys %$args ) {
        my ($id) = ( $key =~ /ce(.+)$/ );
        my $key_val = "ce" . $id;
        if ( $id && $args->{$key_val} ) {
            my $sth = $db->prepare(
                "update catalogCategory set extprice = ? where id = ? ");
            $sth->execute( $args->{$key_val}, $id );
            $i = 'ce';

        }
    }
    foreach my $key ( keys %$args ) {
        my ($id) = ( $key =~ /sd(.+)$/ );
        my $key_val = "sd" . $id;
        if ( $id && $args->{$key_val} ) {
            my $sth = $db->prepare(
                "update catalogCategory set subDate = ? where id = ? ");
            $sth->execute( $args->{$key_val}, $id );
            $i = 'sd';
        }
    }
    if ( $i eq 'sd' ) {
        redirect(
            '/cgi-bin/marketadmin?manage=catalog&action=category_list_d&idCatalog='
                . $args->{idCatalog} );
    }
    if ( $i eq 'ce' ) {
        redirect(
            '/cgi-bin/marketadmin?manage=catalog&action=category_list_p&idCatalog='
                . $args->{idCatalog} );
    }
}

sub admin_catalog_add_catalog() {
    get_template( 'backoffice/templates/catalog/catalog_edit' => $r, );
    return OK;
}

sub admin_catalog_edit_catalog() {
    my $model = Model::Catalog->load( $args->{id} );
    get_template(
        'backoffice/templates/catalog/catalog_edit' => $r,
        item                                        => $model,
        currency => Model::Currency->list(),
    );
    return OK;
}

sub admin_catalog_post_catalog() {
    my $model = Model::Catalog->new($args);
    $model->save();

    redirect(
        '/cgi-bin/marketadmin?manage=catalog&action=edit_catalog&reload=1&id='
            . $model->{id} );
    return OK;
}

sub admin_catalog_delete_catalog() {
    return NOT_FOUND unless $args->{id};
    my $model = Model::Catalog->load( $args->{id} ) or return NOT_FOUND;
    $model->delete();
    return OK;
}

sub admin_catalog_category_list() {
    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $args->{idCatalog} ),
    );

    return OK;
}

sub admin_catalog_category_list_d() {
    get_template(
        'backoffice/templates/catalog/catalog_category_list_d' => $r,
        category => Model::Catalog->load( $args->{idCatalog} ),
    );

    return OK;
}

sub admin_catalog_category_list_p() {
    get_template(
        'backoffice/templates/catalog/catalog_category_list_p' => $r,
        category => Model::Catalog->load( $args->{idCatalog} ),
    );

    return OK;
}

sub admin_catalog_edit_contact() {
    my $sth
        = $db->prepare(
        "select * from catalogContacts where idCatalog = ? AND idMod = ? limit 1;"
        );
    $sth->execute( $args->{idCatalog}, $args->{idMod} );
    my $item = $sth->fetchrow_hashref();

    my $xmodel = Model::SaleMod->load( $args->{idMod} );
    get_template(
        'backoffice/templates/catalog/catalog_edit_contact' => $r,
        item                                                => $item,
        sitem                                               => $xmodel,
    );

    return OK;
}

sub admin_catalog_add_brand_to_category() {
    my $model = Model::Catalog->load( $args->{'idCatalog'} )
        or return NOT_FOUND;
    my $sth
        = $db->prepare(
        "update catalogCategory set brands = concat(brands,',',?) where idCatalog = ? and idCat = ?"
        );
    $sth->execute( $args->{'idBrand'}, $model->{'id'},
        $args->{'idCategory'} );

    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $model->{id} ),
    );
    return OK;
}

sub admin_catalog_del_brand_from_category() {
    my $model = Model::Catalog->load( $args->{'idCatalog'} )
        or return NOT_FOUND;
    my $brands = $args->{'from'};
    my $brand  = $args->{'idBrand'};
    $brands =~ s/^$brand$/0/;
    $brands =~ s/^$brand\,//;
    $brands =~ s/\,$brand\,/\,/;
    $brands =~ s/\,$brand$//;
    $brands =~ s/\,$//;
    $brands =~ s/^\,//;
    $brands = '0' if $args->{'all'} eq '1';
    my $sth
        = $db->prepare(
        "update catalogCategory set brands = ? where idCatalog = ? and idCat = ?"
        );
    $sth->execute( $brands, $model->{'id'}, $args->{'idCategory'} );

    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $model->{id} ),
    );
    return OK;
}

sub admin_catalog_add_prod_to_category() {
    my $model = Model::Catalog->load( $args->{'idCatalog'} )
        or return NOT_FOUND;
    my $mod = Model::SaleMod->load( $args->{'idMod'} ) or return NOT_FOUND;

    if ( $mod->{'idCategory'} eq $args->{'idCategory'} ) {
        my $sth
            = $db->prepare(
            "update catalogCategory set mods = concat(mods,',',?) where idCatalog = ? and idCat = ?"
            );
        $sth->execute( $args->{'idMod'}, $model->{'id'},
            $args->{'idCategory'} );
    }

    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $model->{id} ),
    );
    return OK;
}

sub admin_catalog_del_prod_from_category() {
    my $model = Model::Catalog->load( $args->{'idCatalog'} )
        or return NOT_FOUND;
    my $mods = $args->{'from'};
    my $mod  = $args->{'prod'};
    my $sth  = $db->prepare(
        "select mods from catalogCategory where idCatalog = ? and idCat = ?");
    $sth->execute( $model->{'id'}, $args->{'idCategory'} );
    my $mods = $sth->fetchrow_array();

    $mods =~ s/^$mod$/0/;
    $mods =~ s/^$mod\,//;
    $mods =~ s/\,$mod\,/\,/;
    $mods =~ s/\,$mod$//;
    $mods =~ s/\,$//;
    $mods =~ s/^\,//;
    $mods = '0' if $args->{'all'} eq '1';
    my $sth
        = $db->prepare(
        "update catalogCategory set mods = ? where idCatalog = ? and idCat = ?"
        );
    $sth->execute( $mods, $model->{'id'}, $args->{'idCategory'} );

    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $model->{id} ),
    );
    return OK;
}

sub admin_catalog_post_contact() {
    my $model = Model::CatalogContacts->new($args);
    $model->save();

    my $sth
        = $db->prepare(
        "select * from catalogContacts where idCatalog = ? AND idMod = ? limit 1;"
        );
    $sth->execute( $args->{idCatalog}, $args->{idMod} );
    my $item = $sth->fetchrow_hashref();

    my $xmodel = Model::SaleMod->load( $args->{idMod} );
    get_template(
        'backoffice/templates/catalog/catalog_edit_contact' => $r,
        item                                                => $item,
        sitem                                               => $xmodel,
    );
    return OK;
}

sub admin_catalog_products_list() {
    get_template(
        'backoffice/templates/catalog/catalog_products_list' => $r,
        catalog => Model::Catalog->load( $args->{id} ),
    );

    return OK;
}

sub admin_catalog_simple_list() {

    get_template(
        'backoffice/templates/catalog/catalog_products_simple_list' => $r,
        catalog => Model::Catalog->load( $args->{id} ),
    );
    return OK;
}

sub admin_catalog_category_products_list() {
    get_template(
        'backoffice/templates/catalog/catalog_products_list_category' => $r,
        catalog => Model::Catalog->load( $args->{idCatalog} ),
    );
    return OK;
}

sub admin_catalog_delete_parent_category() {
    my $sth = $db->prepare('select id from category where idParent = ?;');
    $sth->execute( $args->{id} );
    while ( my $item = $sth->fetchrow_hashref ) {
        my $dsth = $db->prepare(
            "delete from catalogCategory where idCatalog = ? AND idCat = ?");
        $dsth->execute( $args->{idCatalog}, $item->{id} );
    }
    redirect(
        '/cgi-bin/marketadmin?manage=catalog&action=category_list&idCatalog='
            . $args->{idCatalog} );
}

sub admin_catalog_active_parent_category() {
    my $sth = $db->prepare('select id from category where idParent = ?;');
    $sth->execute( $args->{id} );
    while ( my $item = $sth->fetchrow_hashref ) {
        my $psth
            = $db->prepare(
            'select isPublic from catalogCategory where idCatalog = ? AND idCat = ?;'
            );
        $psth->execute( $args->{idCatalog}, $item->{id} );
        $psth = $psth->fetchrow_hashref;
        if   ( $psth->{isPublic} ) { $psth->{isPublic} = 0; }
        else                       { $psth->{isPublic} = 1; }
        my $dsth
            = $db->prepare(
            "update catalogCategory set isPublic = ? where idCatalog = ? AND idCat = ?"
            );
        $dsth->execute( $psth->{isPublic}, $args->{idCatalog}, $item->{id} );
    }
    redirect(
        '/cgi-bin/marketadmin?manage=catalog&action=category_list&idCatalog='
            . $args->{idCatalog} );
}

sub admin_catalog_category_copy() {
    my $model = Model::Catalog->load( $args->{idCatalogFrom} )
        or return NOT_FOUND;
    my $model = Model::Catalog->load( $args->{idCatalogTo} )
        or return NOT_FOUND;
    my $sth = $db->prepare("delete from catalogCategory where idCatalog = ?");
    $sth->execute( $args->{idCatalogTo} );

    my $sth
        = $db->prepare(
        "REPLACE catalogCategory (idCatalog,idCat,isPublic,deleted,extprice,subDate,brands,mods) SELECT '"
            . $args->{idCatalogTo}
            . "',idCat,isPublic,'0', extprice, subDate,brands,mods from catalogCategory where idCatalog = ?;"
        );
    $sth->execute( $args->{idCatalogFrom} );
    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        'category' => Model::Catalog->load( $args->{idCatalogFrom} ),
    );

    return OK;
}

sub admin_catalog_category_post() {
    my $cat = Model::Category->load( $args->{idCat} );
    if ( scalar( $cat->parent ) ) {

        if ( scalar( $cat->childs_front ) ) {
            my $sth
                = $db->prepare(
                "REPLACE catalogCategory (idCatalog,idCat,isPublic,deleted,extprice,subDate) SELECT '"
                    . $args->{idCatalog}
                    . "',id,isPublic,'0','10','62'  from category where idParent = ? and deleted != 1 and isPublic = 1;"
                );
            $sth->execute( $args->{idCat} );
        }
        else {
            my $dec = Model::CatalogCategory->new($args);
            $dec->save();
        }
        get_template(
            'backoffice/templates/catalog/catalog_category_list' => $r,
            category => Model::Catalog->load( $args->{idCatalog} ),
        );
        return OK;
    }
    return NOT_FOUND;
}

sub admin_category_off() {
    my $m = Model::Category->load($args->{idCat});
    $m->{isPublic} = 0;
    
    $m->salemods_off();
    $m->childs_off();
    
    $m->save();
    
    print "OK";
    return OK;
}


sub admin_catalog_active_category() {
    my $dec = Model::CatalogCategory->new($args);
    $dec->save();
    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $args->{idCatalog} ),
    );
    return OK;
}

sub admin_catalog_delete_category() {
    return NOT_FOUND unless $args->{id} || $args->{idCatalog};
    my $sth = $db->prepare('delete from catalogCategory where id= ?');
    $sth->execute( $args->{id} );

    #$sth->fetchrow_array;

    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $args->{idCatalog} ),
    );

    return OK;
}

sub admin_catalog_prices_grid() {
    get_template(
        'backoffice/templates/catalog/cat_grid/xml_jg_set' => $r,
        items => Model::CatalogPrices->catalog_prices_grid(),
    );
    return OK;
}

sub admin_catalog_prices_grid_xml() {
    $r->content_type('application/xhtml+xml');
    get_template(
        'backoffice/templates/catalog/cat_grid/xml_jg' => $r,
        items => Model::CatalogPrices->catalog_prices_grid(),
    );
    return OK;
}

sub admin_catalog_post_all_cat() {
    my $model = Model::Catalog->load( $args->{idCatalog} );
    $model->catalog_post_all_cat();

    get_template(
        'backoffice/templates/catalog/catalog_category_list' => $r,
        category => Model::Catalog->load( $args->{idCatalog} ),
    );
    return OK;
}

sub admin_catalog_post_catalog_settings() {
    my $catalog = Model::Catalog->load( $args->{idCatalog} );

    if ( $catalog->{type} eq 'xls' ) {
        foreach my $key ( keys %$args ) {
            my ( $option, $id ) = ( $key =~ /(.+)X(.+)$/ );
            if ( $id && $option ) {
                my $key_val = $option . "X" . $id;
                my $model = Model::CatalogSettings->load( $id, 'id' );
                $model->{$option} = $args->{$key_val};
                $model->save();
            }
        }
        $catalog->catalog_drow_xls();
        redirect(
            '/cgi-bin/marketadmin?manage=catalog&action=edit_catalog&reload=1&id='
                . $catalog->{id} );

    }

    if ( $catalog->{type} eq 'csv' ) {
        foreach my $key ( keys %$args ) {
            my ( $option, $id ) = ( $key =~ /(.+)X(.+)$/ );
            if ( $id && $option ) {
                my $key_val = $option . "X" . $id;
                my $model = Model::CatalogSettings->load( $id, 'id' );
                $model->{$option} = $args->{$key_val};
                $model->save();
            }
        }
        my $put = $catalog->{file};
        my $stt = Base::StTemplate->instance( $cfg->{'stt_catalog'} );
        my $arg = ();
        $catalog->catalog_drow_csv();
        $arg->{lib}  = Core->new();
        $arg->{rows} = $catalog->catalog_xls_csv_data();
        $stt->SetAndGenerate(
            'backoffice/templates/catalog/cat_temp/'
                . $catalog->{id} . '_'
                . $catalog->{type} . '.html',
            $put, $arg
        );
        redirect(
            '/cgi-bin/marketadmin?manage=catalog&action=edit_catalog&reload=1&id='
                . $catalog->{id} );
    }

    if (   $catalog->{type} ne 'xls'
        && $catalog->{type} ne 'csv'
        && $catalog->{type} ne '' )
    {
        my $put = $catalog->{file};
        my $stt = Base::StTemplate->instance( $cfg->{'stt_catalog'} );
        my $arg = ();
        $arg->{lib}       = Core->new();
        $arg->{cat_list}  = $catalog->catalog_get_xml_cat();
        $arg->{prod_list} = $catalog->catalog_get_xml_prod();
        $stt->SetAndGenerate(
            'backoffice/templates/catalog/cat_temp/'
                . $catalog->{type} . '.html',
            $put, $arg
        );
        redirect(
            '/cgi-bin/marketadmin?manage=catalog&action=edit_catalog&reload=1&id='
                . $catalog->{id} );
    }
}

sub admin_catalog_generate() {
    my $sth
        = $db->prepare(
        'select id as id from catalog where isPublic = 1 and deleted != 1 order by name'
        );
    $sth->execute();
    while ( my $item = $sth->fetchrow_hashref ) {
        my $catalog = Model::Catalog->load( $item->{id} );
        if ( $catalog->{type} eq 'xls' ) {
            $catalog->catalog_drow_xls();

        }
        if ( $catalog->{type} eq 'csv' ) {
            my $put = $catalog->{file};
            my $stt = Base::StTemplate->instance( $cfg->{'stt_catalog'} );
            my $arg = ();
            $catalog->catalog_drow_csv();
            $arg->{lib}  = Core->new();
            $arg->{rows} = $catalog->catalog_xls_csv_data();
            $stt->SetAndGenerate(
                'backoffice/templates/catalog/cat_temp/'
                    . $catalog->{id} . '_'
                    . $catalog->{type} . '.html',
                $put, $arg
            );

        }
        if (   $catalog->{type} ne 'xls'
            && $catalog->{type} ne 'csv'
            && $catalog->{type} ne '' )
        {
            #$catalog->catalog_get_xml_prod();
            my $put = $catalog->{file};
            my $stt = Base::StTemplate->instance( $cfg->{'stt_catalog'} );
            my $arg = ();
            $arg->{cat_list}  = $catalog->catalog_get_xml_cat();
            $arg->{prod_list} = $catalog->catalog_get_xml_prod();
            $stt->SetAndGenerate(
                'backoffice/templates/catalog/cat_temp/'
                    . $catalog->{type} . '.html',
                $put, $arg
            );

        }
    }
    redirect('/cgi-bin/marketadmin?manage=catalog&action=list');
}

sub admin_catalog_drop_catalog() {
    my $catalog = Model::Catalog->load( $args->{id} );
    $catalog->delete();
    return OK;
}
####  ####
sub admin_excategory() {
    get_template( 'backoffice/templates/excategory/tree' => $r, );
    return OK;
}

sub admin_excategory_items() {

    get_template( 'backoffice/templates/excategory/tree_items' => $r, );
    return OK;
}
####  ####
sub admin_gallery_add() {
    return NOT_FOUND unless $args->{name};
    my $gallery = Core::Gallery->new( $args->{name} );

    my $fh = &Tools::get_multipart_request_param_fname( $r, 'file' );
    $gallery->add($fh);
    $r->headers_out->set( Location => $r->headers_in->{Referer} );
    return REDIRECT;
}

sub admin_gallery_changeorder() {
    return NOT_FOUND unless $args->{id};
    my $img = Core::Gallery::Image->load( $args->{id} ) or return NOT_FOUND;
    $img->changeorder( $args->{order} );
    if ( $args->{idCat} ) {
        redirect( '/cgi-bin/marketadmin?manage=category&action=edit&id='
                . $args->{idCat} );
    }
    if ( $args->{idCats} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=cat_page_salemods&action=list_sort&idCat='
                . $args->{idCats} );
    }
    if ( $args->{arp_idSection} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=gallery_section&reload=1&id='
                . $args->{arp_idSection} );
    }
    if ( $args->{arp_idPage} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=gallery_page&id='
                . $args->{arp_idPage} );
    }
    if ( $args->{idBrand} ) {
        redirect( '/cgi-bin/marketadmin?manage=brands&action=edit&id='
                . $args->{idBrand} );
    }
    if ( $args->{idMod} ) {
        redirect( '/cgi-bin/marketadmin?manage=salemods&action=gallery&id='
                . $args->{idMod} );
    }
}

sub admin_gallery_delete() {
    return NOT_FOUND unless $args->{id};
    my $img = Core::Gallery::Image->load( $args->{id} ) or return NOT_FOUND;
    $img->delete();
    if ( $args->{idCats} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=cat_page_salemods&action=list_sort&idCat='
                . $args->{idCats} );
    }

    if ( $args->{idCat} ) {
        redirect( '/cgi-bin/marketadmin?manage=category&action=edit&id='
                . $args->{idCat} );
    }

    if ( $args->{idMod} ) {
        redirect( '/cgi-bin/marketadmin?manage=salemods&action=gallery&id='
                . $args->{idMod} );
    }

    if ( $args->{arp_idSection} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=gallery_section&reload=1&id='
                . $args->{arp_idSection} );
    }
    if ( $args->{arp_idPage} ) {
        redirect(
            '/cgi-bin/marketadmin?manage=apr_pages&action=gallery_page&reload=1&id='
                . $args->{arp_idPage} );
    }
}
####  ####
sub admin_payment_add() {

    get_template( 'backoffice/templates/payment/edit' => $r, );
    return OK;
}

sub admin_payment_post() {
    my $model = Model::Payment->new($args);
    $model->save();

    $r->headers_out->set( Location =>
            '/cgi-bin/marketadmin?manage=payment&action=edit&reload=list&id='
            . $model->{id} );
    return REDIRECT;
}

sub admin_payment_edit() {
    return NOT_FOUND unless $args->{id};
    get_template(
        'backoffice/templates/payment/edit' => $r,
        payment => Model::Payment->load( $args->{id} ),
    );
    return OK;
}

sub admin_payment() {
    get_template( 'backoffice/templates/payment/list' => $r, );
    return OK;
}
####  ####
sub admin_offices_add() {
    get_template( 'backoffice/templates/offices/edit' => $r, );
    return OK;
}

sub admin_offices_post() {
    my $model = Model::Office->new($args);
    $model->save();

    $r->headers_out->set( Location =>
            '/cgi-bin/marketadmin?manage=offices&action=edit&reload=list&id='
            . $model->{id} );
    return REDIRECT;
}

sub admin_offices_edit() {
    return NOT_FOUND unless $args->{id};
    get_template(
        'backoffice/templates/offices/edit' => $r,
        office => Model::Office->load( $args->{id} ),
    );
    return OK;
}

sub admin_offices() {
    get_template( 'backoffice/templates/offices/list' => $r, );
    return OK;
}

sub admin_office_schedule() {
    use Model::Office::Schedule;
    if ( $args->{'dbaction'} eq 'save' ) {
        my $day = Model::Office::Schedule->new($args);
        $day->save();
    }
    elsif ( $args->{'dbaction'} eq 'delete' ) {
        my $day = Model::Office::Schedule->new($args);
        $day->{'deleted'} = '1';
        $day->save();
    }
    get_template(
        'backoffice/templates/offices/schedule' => $r,
        'office' => Model::Office->load( $args->{idOffice} ),
    );
    return OK;
}

sub admin_office_phones() {
    use Model::Office::Phones;

    if ( $args->{'dbaction'} eq 'save' ) {
        my $phone = Model::Office::Phones->new($args);
        $phone->save();
    }

    elsif ( $args->{'dbaction'} eq 'delete' && exists $args->{'id'} ) {

        my $phone = Model::Office::Phones->load( $args->{'id'} );

        $phone->delete();

    }

    get_template(
        'backoffice/templates/offices/phones' => $r,
        'office' => Model::Office->load( $args->{idOffice} ),
    );

    return OK;
}

####  ####
sub admin_currency_post() {

    my $model = Model::Currency->new($args);

    $r->headers_out->add( Location =>
            '/cgi-bin/marketadmin?manage=currency&action=edit&reload=list&id='
            . $args->{id} );
    if ( $args->{dbaction} eq 'update' or $args->{dbaction} eq 'insert' ) {
        $model->save();
        return REDIRECT;
    }

    return REDIRECT;
}

sub admin_currency_add() {

    get_template( 'backoffice/templates/currency/add' => $r, );

    return OK;
}

sub admin_currency_edit() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/currency/edit' => $r,
        currency => Model::Currency->load( $args->{id} ),
    );

    return OK;
}

sub admin_currency() {
    get_template(
        'backoffice/templates/currency/list' => $r,
        currencys                            => Model::Currency->list(),
    );
    return OK;
}
####  ####
sub admin_meta_url() {

    get_template(
        'backoffice/templates/meta_url/list' => $r,
        MetaUrls                             => Model::Meta::Url->list(),
    );
    return OK;
}

sub admin_meta_url_add() {

    get_template( 'backoffice/templates/meta_url/add' => $r, );

    return OK;
}

sub admin_meta_url_post() {
    unless ($args->{url}
        and $args->{description}
        and $args->{title}
        and $args->{keywords} )
    {
        return &admin_meta_url_add()  if $args->{dbaction} eq 'insert';
        return &admin_meta_url_edit() if $args->{dbAction} eq 'update';
    }
    $args->{url} = '/' . $args->{url} if $args->{url} !~ /^\//;

    my $model = Model::Meta::Url->new($args);
    $r->headers_out->add( Location =>
            '/cgi-bin/marketadmin?manage=meta_url&action=add&reload=list&id='
            . $args->{id} )
        if $args->{dbaction} eq 'insert';
    $r->headers_out->add( Location =>
            '/cgi-bin/marketadmin?manage=meta_url&action=edit&reload=list&id='
            . $args->{id} )
        if $args->{dbaction} eq 'update';
    if ( $args->{dbaction} eq 'update' or $args->{dbaction} eq 'insert' ) {
        $model->save();
        return REDIRECT;
    }

    return REDIRECT;
}

sub admin_meta_url_delete() {
    my $model = Model::Meta::Url->load( $args->{id} ) or return NOT_FOUND;
    $model->delete();
    $r->headers_out->set( Location =>
            '/cgi-bin/marketadmin?manage=meta&action=url_add&reload=list' );
    return REDIRECT;
}

sub admin_meta_delete() {
    my $model = Model::Meta->load( $args->{id} ) or return NOT_FOUND;
    $model->delete();
    return OK;
}

sub admin_meta_url_edit() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/meta_url/edit' => $r,
        meta => Model::Meta::Url->load( $args->{id} ),
    );

    return OK;
}

sub admin_meta() {

    get_template(
        'backoffice/templates/meta/list' => $r,
        MetaUrls                         => Model::Meta->list(),
    );
    return OK;
}

sub admin_meta_post() {
    unless ($args->{id}
        and $args->{description}
        and $args->{title}
        and $args->{keywords} )
    {
        return &admin_meta_edit();
    }

    my $model = Model::Meta->new($args);
    $r->headers_out->add( Location =>
            '/cgi-bin/marketadmin?manage=meta&action=edit&reload=list&id='
            . $args->{id} );
    if ( $args->{dbaction} eq 'update' ) {
        $model->save();
        return REDIRECT;
    }

    return REDIRECT;
}

sub admin_meta_edit() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/meta/edit' => $r,
        meta                             => Model::Meta->load( $args->{id} ),
    );

    return OK;
}
####  ####


sub admin_brands_clear_prices {
	if($args->{idBrand}){
        my $sth = $db->prepare("update salemods set price = 0 where idBrand = ? ");
        $sth->execute($args->{idBrand});
		redirect("/cgi-bin/marketadmin?manage=brands&action=edit&id=".$args->{idBrand});
	}
}

sub admin_brands() {

    my $list = ModelList->new( 'Model::Brand', $args->{page}, 100 );

    $list->filter( 'isPublic' => '1' ) if $args->{'isPublic'};
    $list->order('name');
    $list->load();

    get_template(
        'backoffice/templates/brands/list' => $r,
        brands                             => $list,
        page                               => $args->{page},
    );

    return OK;
}

sub admin_brand_mods() {

    my $list = ModelList->new( 'Model::SaleMod', $args->{page}, 1000 );
    $list->filter( 'idBrand' => $args->{'idBrand'} ) if $args->{'idBrand'};
    $list->order('idCategory');
    $list->load();

    get_template(
        'backoffice/templates/brands/list_mods' => $r,
        mods                                    => $list,
        page                                    => $args->{page},
    );

    return OK;
}

sub admin_brands_show_products() {

    my $list = ModelList->new( 'Model::SaleMod', $args->{page}, 100 );
    $list->filter( 'idBrand' => $args->{idBrand} );
    $list->order('idCategory,isPublic desc,name');
    $list->load();

    get_template(
        'backoffice/templates/brands/product_list' => $r,
        mods                                       => $list,
        page                                       => $args->{page},
        brand => Model::Brand->load( $args->{idBrand} ),
    );

    return OK;
}

sub admin_brands_edit() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/brands/edit' => $r,
        brand => Model::Brand->load( $args->{id} ),
    );

    return OK;
}

sub admin_brands_post() {
    $args->{'alias'} = Base::Translate->translate( $args->{'name'} );
    my $model = Model::Brand->new($args);

    if ( $args->{dbaction} eq 'insert' or $args->{dbaction} = 'update' ) {
        if ( $model->save() ) {
            print 'Looking good';
            $r->headers_out->add( Location =>
                    '/cgi-bin/marketadmin?manage=brands&action=edit&id='
                    . $model->newid() );
        }
        else {
            print 'Failed';
        }
    }
    elsif ( $args->{dbaction} eq 'delete' ) {
    }
    redirect(
        '/cgi-bin/marketadmin?manage=brands&action=edit&id=' . $args->{id} );
}

sub admin_brands_add() {

    get_template( 'backoffice/templates/brands/add' => $r, );
    return OK;
}

sub admin_brands_setimage() {
    return OK unless $args->{id};
    my $brand = Model::Brand->load( $args->{id} ) or return NOT_FOUND;
    redirect( '/cgi-bin/marketadmin?manage=brands&action=gallery&reload=1&id='
            . $brand->{id} );
    return OK;
}

sub admin_brands_add_remote_img() {
    my $model = Model::Brand->load( $args->{id} ) or return NOT_FOUND;
    $model->add_remote_img( $args->{remote_file}, $args->{name} );
    redirect(
        '/cgi-bin/marketadmin?manage=brands&action=edit&id=' . $args->{id} );
}
####  ####
sub admin_cat_top_menu_post() {
    my $model = Model::CategoryTopMenu->new($args);
    $model->{idCat} = $args->{idCat};
    $model->{col}   = $args->{col};
    $model->{col2}  = $args->{col2};
    $model->save();
    redirect( '/cgi-bin/marketadmin?manage=category&action=edit&id='
            . $args->{idCat} );
}

sub admin_category_add_remote_img() {
    my $model = Model::Category->load( $args->{id} ) or return NOT_FOUND;
    $model->add_remote_img( $args->{remote_file} );
    redirect( '/cgi-bin/marketadmin?manage=category&action=edit&id='
            . $args->{id} );
}

sub admin_category_catpriceautogen () {
    return undef unless $args->{idCategory};
    return undef unless $args->{categoryLevel};
    my @buf;
    my $idCat  = $args->{idCategory};
    my $level  = $args->{categoryLevel};
    my $valuep = $args->{valuep} || '0';
    my $sth;
    if ( $level eq 'first' ) {
        $sth
            = $db->prepare(
            'select s.id from salemods s inner join category c1 inner join category c2 on c2.idParent = c1.id where s.idCategory = c2.id and c1.idParent = ?'
            );
    }
    elsif ( $level eq 'second' ) {
        $sth
            = $db->prepare(
            'select s.id from salemods s inner join category c where s.idCategory = c.id and c.idParent = ?'
            );
    }
    elsif ( $level eq 'third' ) {
        $sth = $db->prepare('select id from salemods where idCategory = ?');
    }
    $sth->execute($idCat);

    while ( my ($id) = $sth->fetchrow_array ) {
        my $sthd = $db->prepare(
            'update salemods set priceAutogen = ? where id = ?');
        $sthd->execute( $valuep, $id );
    }
    return OK;
}

sub admin_category_priceautogen () {

    return undef unless $args->{idCategory};
    return undef unless $args->{categoryLevel};
    my @buf;

    my $idCat = $args->{idCategory};
    my $level = $args->{categoryLevel};
    my $sth;
    if ( $level eq 'zero' ) {
        $sth
            = $db->prepare(
            'select s.id from salemods as s inner join category as c3 on c3.id = s.idCategory inner join category as c2 on c2.id = c3.idParent inner join category as c1 on c1.id = c2.idParent where c1.idParent = 0 and c3.isPublic and s.priceautogen and s.id != ?'
            );
    }
    elsif ( $level eq 'first' ) {
        $sth
            = $db->prepare(
            'select s.id from salemods s inner join category c1 inner join category c2 on c2.idParent = c1.id where s.idCategory = c2.id and c1.idParent = ?'
            );
    }
    elsif ( $level eq 'second' ) {
        $sth
            = $db->prepare(
            'select s.id from salemods s inner join category c where s.idCategory = c.id and c.idParent = ?'
            );
    }
    elsif ( $level eq 'third' ) {
        $sth = $db->prepare('select id from salemods where idCategory = ?');
    }
    elsif ( $level eq 'all' ) {
        $sth = $db->prepare(
            'select id from salemods where not deleted and id != ?');
    }
    $sth->execute($idCat);
    use Model::SaleMod;

    while ( my ($id) = $sth->fetchrow_array ) {
        my $res  = {};
        my $prod = Model::SaleMod->load($id);
        $res->{id}           = $prod->{id};
        $res->{name}         = $prod->{name};
        $res->{old_price}    = $prod->{price};
        $res->{priceAutogen} = $prod->{priceAutogen};
        $res->{public}       = $prod->{isPublic};
        $prod->priceautogen();
        $res->{new_price} = $prod->{price};

        push @buf, $res;
    }

    get_template(
        'backoffice/templates/price/priceupdate' => $r,
        'data'                                   => \@buf,
        'cat' => Model::Category->load($idCat),
    );

    return OK;
}

sub admin_category() {

    my $top = { childs => Model::Category->list(0), };
    my $category = Model::Category->load( $args->{id} );
    get_template(
        'backoffice/templates/category/list' => $r,
        top                                  => $top,
        category                             => $category,
    );
    return OK;
}

sub admin_category_edit() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/category/edit' => $r,
        category => Model::Category->load( $args->{id} ),
    );
    return OK;
}

sub admin_category_add() {
    get_template(
        'backoffice/templates/category/add' => $r,
        category => Model::Category->load( $args->{id} ),
    );
    return OK;
}

sub admin_category_fixorder() {
    my $model = Model::Category->load( $args->{id} );
    $model->changeorder( $args->{position} );
    $r->headers_out->add(
        Location => '/cgi-bin/marketadmin?manage=category&action=edit&id='
            . $model->{id} );

    return REDIRECT;
}

sub admin_category_post() {
    if ( $args->{idParent} != 0 ) {
        return NOT_FOUND if $args->{idParent} eq $args->{id};
    }

    ######### for redirect 301
    if ( $args->{id} ) {

    }
    ######### for redirect 301

    my $model = Model::Category->new($args);

    if ( $args->{dbaction} eq 'delete' ) {
    }
    else {
        $model->{alias} = Base::Translate->translate( $args->{name} )
            if !$args->{alias};
        $model->save();
        redirect( '/cgi-bin/marketadmin?manage=category&action=edit&id='
                . $model->{id} );
    }
}

sub admin_category_price_bar() {
    get_template(
        'backoffice/templates/category/price_bar' => $r,
        category => Model::Category->load( $args->{idCat} ),
    );

    return OK;
}

sub admin_category_post_price_bar() {
    my $sth = $db->prepare('delete from categoryPriceBar where deleted = 1;');
    $sth->execute();

    my $bar = Model::PriceBar->new($args);
    $bar->save();
    redirect( '/cgi-bin/marketadmin?manage=category&action=price_bar&idCat='
            . $bar->{idCat}
            . '' );
    return OK;
}

sub admin_category_copy_price_bar() {
    my $bar = Model::Category->load( $args->{id} );
    $bar->bar_copy( $args->{idCat} );
    redirect( '/cgi-bin/marketadmin?manage=category&action=price_bar&id='
            . $bar->{idCat}
            . '' );
    return OK;
}

sub admin_category_accessories() {
    get_template(
        'backoffice/templates/category/accessories' => $r,
        category => Model::Category->load( $args->{idCat} ),
    );

    return OK;
}

sub admin_category_post_accessories() {

    my $dec = Model::categoryAccessories->new($args);
    $dec->save();
    get_template(
        'backoffice/templates/category/accessories' => $r,
        category => Model::Category->load( $dec->{idCat} ),
    );

    return OK;
}

sub admin_category_dec() {
    get_template(
        'backoffice/templates/category/dec' => $r,
        category => Model::Category->load( $args->{idCat} ),
    );

    return OK;
}

sub admin_category_post_dec() {
    my $dec = Model::CDec->new($args);
    $dec->save();
    get_template(
        'backoffice/templates/category/dec' => $r,
        category => Model::Category->load( $dec->{idCat} ),
    );

    return OK;
}

sub admin_category_meta() {
    get_template(
        'backoffice/templates/category/meta' => $r,
        category => Model::Category->load( $args->{idCat} ),
    );

    return OK;
}

sub admin_category_post_meta() {
    my $dec = Model::CMeta->new($args);
    $dec->save();
    get_template(
        'backoffice/templates/category/meta' => $r,
        category => Model::Category->load( $dec->{idCat} ),
    );

    return OK;
}

sub admin_category_post_adec() {
    my $adec = Model::CategoryAltDec->new($args);
    $adec->save();
    get_template(
        'backoffice/templates/category/dec' => $r,
        category => Model::Category->load( $adec->{idCat} ),
    );

    return OK;
}

sub admin_category_post_adec_descr() {
    my $adec = Model::CategoryAltDec->new($args);
    $adec->save();
    redirect(
        '/cgi-bin/marketadmin?manage=cat_page_salemods&action=list_sort&idCat='
            . $args->{idCat} );
}

sub admin_category_salerprices_zeroing() {
    return NOT_FOUND unless $args->{idCategory};
    my $sth = $db->prepare('select id from salemods where idCategory = ?');
    $sth->execute( $args->{idCategory} );
    while ( my $item = $sth->fetchrow_hashref ) {
        my $sth1 = $db->prepare(
            'update salerprices set price = 0 where idSaleMod = ?');
        $sth1->execute( $item->{id} );

        my $sth2 = $db->prepare('update salemods set price = 0 where id = ?');
        $sth2->execute( $item->{id} );
    }
    redirect( '/cgi-bin/marketadmin?manage=subprice&cat_id='
            . $args->{idCategory} );
}

sub admin_category_salemods_rerite() {
    my @buf;
    my $string_strong;
    my $sth
        = $db->prepare(
        'select id, name, alias from salemods name where idCategory = ? order by name'
        );

    $sth->execute( $args->{idCat} );
    while ( my $item = $sth->fetchrow_hashref ) {

        if ( $args->{string} ) {

            $string_strong = '<strong>' . $args->{string} . '</strong>';

            if ( $args->{replace_string} || $args->{replace_string} eq '0' ) {

                if ( $args->{replace_string} eq '0' ) {
                    $string_strong = '';
                }
                else {
                    $string_strong = $args->{replace_string};
                }

            }

            $item->{name} =~ s/$args->{string}/$string_strong/;

            if ( $args->{inDb} != 0 && $item->{name} ) {
                my $model = Model::SaleMod->load( $item->{id} );
                if ( $args->{inDb} == 1 ) {
                    $model->{name} = $item->{name};
                }
                if ( $args->{inDb} == 2 ) {
                    $model->{name} = $item->{name};
                    $model->{alias}
                        = Base::Translate->translate( $model->{name} );
                    $item->{alias} = $model->{alias};
                }
                $model->save();
            }
        }
        push @buf, $item;
    }

    get_template(
        'backoffice/templates/category/salemods_rerite' => $r,
        'category' => Model::Category->load( $args->{idCat} ),
        list       => \@buf,
    );
    return OK;
}

sub admin_category_simple_list() {

    get_template( 'backoffice/templates/category/simple_list' => $r, );
    return OK;
}

sub admin_categoryAddons() {

    my ( @cat, @cat2level, @cat3level );

    my $sth = $db->prepare("select * from category_addons order by idParent");
    $sth->execute();
    while ( my $item = $sth->fetchrow_hashref() ) {
        push @cat, $item;
    }

    my $sth2
        = $db->prepare(
        "select c1.id,c1.name from category as c1 left join category as c2 on c1.idParent = c2.id  where c2.idParent = 0 and c1.deleted != 1 and c1.isPublic = 1 order by c1.name"
        );
    $sth2->execute();
    while ( my $item2 = $sth2->fetchrow_hashref() ) {
        push @cat2level, $item2;
    }

    my $sth3
        = $db->prepare(
        "select c1.id,c1.name from category as c1 left join category as c2 on c1.idParent = c2.id  left join category as c3 on c2.idParent = c3.id where c3.idParent = 0 and c1.deleted != 1 and c1.isPublic = 1 order by c1.name"
        );
    $sth3->execute();
    while ( my $item3 = $sth3->fetchrow_hashref() ) {
        push @cat3level, $item3;
    }

    get_template(
        'backoffice/templates/settings/category_addons/list' => $r,
        'mycat'                                              => \@cat,
        'cat2level'                                          => \@cat2level,
        'cat3level'                                          => \@cat3level,
    );
    return OK;
}

sub admin_categoryAddons_update() {

    if ( $args->{dbaction} eq 'insert' ) {
        my $sth = $db->prepare(
            "insert into category_addons (idParent,idCategory) value (?,?)");
        $sth->execute( $args->{'idParent'}, $args->{'idCategory'} );

        &admin_categoryAddons();
    }
    elsif ( $args->{dbaction} eq 'update' ) {
        my $sth
            = $db->prepare(
            "update category_addons set idParent = ?,idCategory = ? where id = ?"
            );
        $sth->execute( $args->{'idParent'}, $args->{'idCategory'},
            $args->{'id'} );

        &admin_categoryAddons();
    }
    else {
        my $sth = $db->prepare('delete from category_addons where id = ?');
        $sth->execute( $args->{'id'} );

        &admin_categoryAddons();
    }
}

sub admin_category_set_category_id_parent {

    my $model = Model::Category->load( $args->{id} );

    if ( $model->{id} && $args->{idParent} ) {
        $model->{idParent} = $args->{idParent};
        $model->save();
    }

    return OK;
}

sub admin_simplelist_category_salemods() {

    if ( $args->{id} ) {
        my $model = Model::Category->load( $args->{id} );
        get_template(
            'backoffice/templates/salemods/simple_list' => $r,
            items => $model->salemods_all(),
        );
        return OK;
    }
}
####  ####
sub admin_sales_innerlist() {
    my $template   = 'innerlist';
    my $sort       = 'name';
    my $sort_table = 'sm.';
    my $isPublic   = ' ';
    my $desc;
    my $page = 0;
    my $lim  = 100;
    my @buffer;
    my @salemod_buf;
    my $load_salemod;
    my $filter;

    ############# ivan fix #############################
    if ( !$user->session->get('cat_id') ) {
        my $obj = $user->session->get('cat_id');
        $obj->{cat_id} = $args->{id};
        $user->session->set( 'cat_id' => $obj );
        $user->session->save();
    }

    #if($user->session->get('cat_id')->{cat_id} != $args->{id}){
    #   &admin_filter_delcat();
    #}
    ############# ivan fix #############################

    my $category = Model::Category->load( $args->{id} ) or return NOT_FOUND;

    ###isPublic###
    if ( $user->session->get('filter_sales') ) {
        my $obj = $user->session->get('filter_sales');

        if ( $obj->{isPublic} == 1 ) {
            $isPublic = ' and sm.isPublic  = 1 ';
        }

        if ( $obj->{modname} ) {
            $filter = ' and sm.name like "%' . $obj->{modname} . '%" ';
        }

        if ( $obj->{modprice} ) {
            my ( $from, $to ) = split( /-/, $obj->{modprice} );
            if ( $from or $to ) {
                if ( $from and $to ) {
                    $filter .= "and sm.price BETWEEN '$from' AND '$to'";
                }
                elsif ($from) { $filter .= " and sm.price >= $from"; }
                elsif ($to)   { $filter .= " and sm.price <= $to"; }
            }
        }

        if ( $obj->{brands} ) {
            $filter .= " and sm.idBrand in( 0";
            foreach my $bid ( @{ $obj->{brands} } ) {
                $filter .= " ,$bid";
            }
            $filter .= " )";
        }
    }

    ###sort###
    if ( $user->session->get('sort') ) {
        ( $sort, $desc ) = split( /_/, $user->session->get('sort')->{sort} );
        if ( $sort eq 'eprice' ) { $sort = 'eprice'; $sort_table = ''; }
    }

    $sort = "ORDER BY $sort_table" . $sort . " $desc";

    my $csth
        = $db->prepare(
        'select count(sm.id) as scount from salemods sm where sm.idCategory  = ? and sm.deleted != 1 '
            . $isPublic . ' '
            . $filter . ' '
            . $isPublic
            . '' );
    $csth->execute( $args->{id} );
    my $citem = $csth->fetchrow_hashref;

    my $pager = Core::Pager->new( $args->{page}, $lim );
    $pager->setMax( $citem->{scount} );

    my $sth = $db->prepare(
        'select                 sm.id smid,
                   sm.name smname,
                   sm.price smprice,
                   sm.alias salias,
                   sp.price spprice,
                   sp.idSaler idSaler,
                   DATE_FORMAT(sp.updated,"%d.%m.%y") spdate,
                   sm.baseId smbase,
                   sm.isPublic smisPublic,
                   s.name sname,
                   sm.isPublic isPublic,
                   sm.priceAutogen priceAutogen,
                   (sm.price - sp.price) eprice,
                    LENGTH(sm.Description) ldesc,
                    LENGTH(sm.DescriptionFull) ldescf,
                    sm.mpn,
                   TIMESTAMPDIFF(DAY,sp.updated,NOW()) daydif
                from salemods sm
                LEFT JOIN salerminprice sp ON sm.id = sp.idSaleMod
                LEFT JOIN salers s ON sp.idSaler = s.id
                    where sm.idCategory  = ?
                        and sm.deleted != 1
                        ' . $filter . '
                       ' . $isPublic . '
                       ' . $sort . '
                        LIMIT '
            . $pager->getOffset() . ',' . $pager->getLimit() . ' '
    );
    $sth->execute( $args->{id} );
    my $i;

    while ( my $item = $sth->fetchrow_hashref ) {
        push @buffer, $item;
    }
    my $limit = $pager->getLimit();

    get_template(
        'backoffice/templates/sales/innerlist' => $r,
        category                               => $category,
        sales                                  => \@buffer,
        pager                                  => $pager,
        scount                                 => $citem->{scount},
    );
    return OK;
}

sub admin_sales_video() {
    get_template(
        'backoffice/templates/salemods/video' => $r,
        model => Model::SaleMod->load( $args->{id} )
    );
    return OK;
}

sub admin_video_post() {
    my $model = Model::Video->new($args);
    $model->save();
    if ( $args->{table_name} eq 'salemods' ) {
        redirect(
            '/cgi-bin/marketadmin?manage=sales&action=video&table=salemods&id='
                . $model->{idTable} );
    }
}
####  ####
sub admin_salemod_set_category_id {

    my $smodel = Model::SaleMod->load( $args->{id} );

    my $ocmodel = Model::Category->load( $smodel->{idCategory} );
    my $ncmodel = Model::Category->load( $args->{idCategory} );

    if ( $smodel->{id} && $ocmodel->{id} && $ncmodel->{id} ) {
        $smodel->{idCategory} = $ncmodel->{id};
        $smodel->save();
    }

    return OK;
}

sub admin_salemod_features {

    use Model::FeatureGroups;
    use Model::Feature;

    my $salemod = Model::SaleMod->load( $args->{id} );
    my $feature_groups
        = Model::FeatureGroups->list_active_main( $salemod->{idCategory} );

    my $sth
        = $db->prepare(
        "select distinct(f.value) from features f inner join feature_groups g on g.id = f.idFeatureGroup where g.type = 'string' and g.idCategory = ?"
        );
    $sth->execute( $salemod->{idCategory} );

    my @autocomplite = ();
    while ( my ($value) = $sth->fetchrow_array() ) {
        push @autocomplite, $value;
    }

    my $sth = $db->prepare(
        "select id,idFeatureGroup from features where idSalemod = ? ");
    $sth->execute( $salemod->{id} );

    my $features = ();
    while ( my ( $id, $idFeatureGroup ) = $sth->fetchrow_array() ) {
        $features->{$idFeatureGroup} = Model::Feature->load($id);
    }

    get_template(
        'backoffice/templates/features/product/edit' => $r,
        'feature_groups'                             => $feature_groups,
        'autocomplite'                               => \@autocomplite,
        'model'                                      => $salemod,
        'features'                                   => $features,
        'salemod_id'                                 => $args->{id},
    );
    return OK;
}

sub admin_salemod_features_post {

    my $features = ();
    foreach ( keys %{$args} ) {
        if (/^feature_(\d+)/) {
            $features->{$1} = $args->{$_};
        }
    }

    my $sth
        = $db->prepare(
        "replace into features(idSaleMod,idFeatureGroup,value) values(?,?,?)"
        );
    foreach my $key ( keys %{$features} ) {
        $sth->execute( $args->{id}, $key, $features->{$key} );
    }

    &admin_salemod_features();
}

sub admin_salemods_copypropertys() {
    my $model = Model::SaleMod->load( $args->{id} );
    warn "\n\n\n $args->{idMod} COPY \n\n\n\n";
    $model->copypropertys( $args->{idMod} );
    redirect( '/cgi-bin/marketadmin?manage=salemods&action=propertys&id='
            . $args->{id} );
}

sub admin_salemods_propertys() {

    admin_salemod_features();
}

sub admin_salemods_add_remote_img() {
    my $model = Model::SaleMod->load( $args->{id} ) or return NOT_FOUND;
    $model = $model->add_remote_img( $args->{remote_file} );
    redirect( '/cgi-bin/marketadmin?manage=salemods&action=gallery&id='
            . $args->{id} );
    return OK;
}

sub admin_salemods_set_category_img() {

    my $model = Model::SaleMod->load( $args->{id} ) or return NOT_FOUND;
    $model = $model->add_remote_img( $args->{remote_file} );

    redirect( '/cgi-bin/marketadmin?manage=salemods&action=gallery&id='.$args->{id} );

    return OK;
}

sub admin_salemods_popular() {
    my $category = Model::Category->load( $args->{id} ) or return NOT_FOUND;

    get_template(
        'backoffice/templates/salemods/popular' => $r,
        category                                => $category,
    );
    return OK;
}

sub admin_salemods_video() {

    return NOT_FOUND unless Model::SaleMod->load( $args->{'idMod'} );

    if ( $args->{'dbaction'} eq 'delete' ) {
        my $sth
            = $db->prepare('delete from video where idTable = ? and id = ?');
        $sth->execute( $args->{'idMod'}, $args->{'id'} );
    }

    redirect( '/cgi-bin/marketadmin?manage=salemods&action=show&id='
            . $args->{'idMod'} );
}

sub admin_salemods_importprices() {

    return NOT_FOUND unless $args->{id};
    $import->price( $args->{id} );
    redirect(
        '/cgi-bin/marketadmin?manage=salemods&action=show&show=prices&id='
            . $args->{id} );
}

sub admin_salemods_soldreport() {
    return NOT_FOUND unless $args->{id};

    get_template(
        'backoffice/templates/salemods/soldreport' => $r,
        model => Model::SaleMod->load( $args->{id} ),
    );
    return OK;
}

sub admin_salemods_image_search_google() {
    return NOT_FOUND unless $args->{id};
    get_template(
        'backoffice/templates/salemods/image_search_google' => $r,
        model => Model::SaleMod->load( $args->{id} ),
    );
    return OK;
}

sub admin_salemods_setimage() {
    my $smod = Model::SaleMod->load( $args->{id} ) or return NOT_FOUND;
    $smod->{idImage} = $args->{img};

    $smod->save();

    redirect( '/cgi-bin/marketadmin?manage=salemods&action=gallery&id='
            . $smod->{id} );
}

sub admin_salemods_gallery() {
    return OK unless $args->{id};

    get_template(
        'backoffice/templates/salemods/gallery' => $r,
        model => Model::SaleMod->load( $args->{id} ),
    );

    return OK;
}

sub admin_salemods_show() {
    return OK unless $args->{id};
    my $model = Model::SaleMod->load( $args->{id} );
    $model = Model::SaleMod->load( $args->{id}, 'mpn' ) unless $model->{id};

    get_template(
        'backoffice/templates/salemods/show' => $r,
        'model'                              => $model,
    );
    return OK;
}

sub admin_salemods_show_price() {
    return OK unless $args->{id};
    my $model = Model::SaleMod->load( $args->{id} );
    if ( $args->{type} eq 'save' ) {
        $args->{type}          = 'show';
        $model->{priceAutogen} = 0;
        $model->{price}        = $args->{set_price};
        $model->save();
    }
    get_template(
        'backoffice/templates/sales/show_price' => $r,
        item => Model::SaleMod->load( $args->{id} ),
    );
    return OK;
}

sub admin_salemods_add() {
    return OK unless $args->{id};
    get_template(
        'backoffice/templates/salemods/add' => $r,
        category => Model::Category->load( $args->{id} ),
    );

    return OK;
}

sub admin_salemods_post_status() {
    return OK unless $args->{id};
    my $model = Model::SaleMod->load( $args->{id} ) or return NOT_FOUND;
    if ( $model->{id} ) {
        $model->{price}    = $args->{price};
        $model->{isPublic} = $args->{isPublic};
        $model->{rating}   = $args->{rating};
        $model->{discount} = $args->{discount};
        $model->save();
    }

    redirect( '/cgi-bin/marketadmin?manage=salemods&action=show&id='
            . $args->{id} );
}

sub admin_salemods_post() {

    if ( !$args->{idCategory} ) {
        return NOT_FOUND;
    }

    if ( $args->{baseId} > 1 ) {
        my $tmp = Model::SaleMod->load( $args->{baseId}, 'id' );

        if ( $tmp->{baseId} != 1 ) {
            delete $args->{baseId};
        }

    }

    else {
        delete $args->{baseId};
    }

    my $model = Model::SaleMod->new($args);

    if ( $args->{dbaction} ne 'delete' ) {
        $model->feel_saler_prices($args) if $args->{updateprices};
        $model->arkhiv($args);
        $model->priceautogen() if $args->{autogenprice};
        my $old_mod = Model::SaleMod->load( $model->{'alias'}, 'alias' );
        if ( $old_mod->{'alias'} ) {
            $model->{alias} = $old_mod->{'alias'};
        }
        else {
            $model->{'alias'} = Base::Translate->translate( $model->{'name'} );
        }
        if ( $old_mod->{'alias'} && $args->{dbaction} eq 'insert' ) {
            $model->{alias} = $old_mod->{'alias'};
            print 'Product with this name alreadi exist ' . $model->errs;
        }
        else {
            unless ( $model->save() ) {
                print 'Failed' . $model->errs;
            }
        }
        $model->{Description} =~ s/\%name\%/$model->{name}/gm
            if $model->{Description} =~ /\%name\%/;
        $model->{DescriptionFull} =~ s/\%name\%/$model->{name}/gm
            if $model->{DescriptionFull} =~ /\%name\%/;
        if ( $args->{price} ne $args->{old_price} ) {
            $model->{price} = $args->{price};
            $model->save();
        }

        if ( $args->{updateprices} ) {
            redirect(
                '/cgi-bin/marketadmin?manage=salemods&action=show&show=prices&id='
                    . $model->{id} );
        }

        else {
            redirect(
                '/cgi-bin/marketadmin?manage=salemods&action=edit&reload=list&id='
                    . $model->{id} );
        }
    }

    else {
        my $model = Model::SaleMod->load( $args->{id}, 'id' );
        $model->delete();
        redirect(
            '/cgi-bin/marketadmin?manage=salemods&action=edit&reload=list');
    }
    return OK;
}

sub admin_salemods_copy() {
    return OK unless $args->{id};

    my $mod = Model::SaleMod->load( $args->{id} );
    $mod->{name}  .= ' copy';
    $mod->{alias} .= '-copy';
    get_template(
        'backoffice/templates/salemods/edit_copy' => $r,
        model                                     => $mod,
        category => Model::Category->load( $mod->{idCategory} ),
    );

    return OK;
}

sub admin_salemods_post_copy() {
    $args->{id} = '';
    if ( !$args->{idCategory} ) {
        return NOT_FOUND;
    }
    my $model = Model::SaleMod->new($args);
    $model->{'alias'} = Base::Translate->translate( $model->{'name'} );
    $model->{baseId} = 0;
    $model->save();

    redirect(
        '/cgi-bin/marketadmin?manage=salemods&action=edit&reload=list&id='
            . $model->{id} );
    return OK;
}

sub admin_salemods_copy_base() {

    return OK unless $args->{id};

    my $bmod = Model::SaleMod->load( $args->{id} );

    if ( $bmod->{baseId} == 0 ) {
        my $cbmod = Model::SaleMod->load( $args->{id} );
        $cbmod->{baseId} = 1;
        $cbmod->save();
    }

    $bmod->{id}          = '';
    $bmod->{GalleryName} = '';
    $bmod->{alias} .= $args->{val} || '-copy_from_base';
    $bmod->{name}  .= $args->{val} || '-copy_from_base';
    $bmod->{idImage} = 0;
    $bmod->{baseId}  = $args->{id};

    my $nmod = Model::SaleMod->new($bmod);
    $nmod->save();
    my $sth = $db->prepare(
        "replace into features(id,idSaleMod,idFeatureGroup,value)
                                select null,?,idFeatureGroup,value
                                from features
                                where idSaleMod = ?"
    );

    $sth->execute( $nmod->{id}, $args->{id} );
    get_template(
        'backoffice/templates/salemods/edit_base' => $r,
        'model'                                   => $nmod,
        'category' => Model::Category->load( $nmod->{idCategory} ),
    );

    return OK;
}

sub admin_salemods_edit() {
    return OK unless $args->{id};
    my $salemod = Model::SaleMod->load( $args->{id} );
    get_template(
        'backoffice/templates/salemods/edit' => $r,
        model                                => $salemod,
        category => Model::Category->load( $salemod->{idCategory} ),
    );

    return OK;
}

sub admin_salemods_description_edit() {
    return OK unless $args->{id};
    my $mod = Model::SaleMod->load( $args->{id} );
    get_template(
        'backoffice/templates/salemods/description' => $r,
        model => $mod,
    );

    return OK;
}


sub admin_salemods_description_post() {
    return OK unless $args->{id};

 use Clean;

    my $diff;

    my $mod = Model::SaleMod->load( $args->{id} );

    foreach(qw/Description DescriptionFull/){
	   $mod->{$_} = Clean->a( $args->{$_} ) ;   
    }
    $mod->save();

    get_template(
        'backoffice/templates/salemods/description' => $r,
        model                                => $mod,
    );

    return OK;
}





sub admin_salemods_public() {
    return OK unless $args->{id};
    return OK unless $args->{idCatgory};

    my $bmodel = Model::SaleMod->load( $args->{id} );
    $bmodel->{isPublic} = $args->{isPublic};
    $bmodel->save();

    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCatgory} );
}

sub admin_salemods_set_autogen() {
    return OK unless $args->{id};
    return OK unless $args->{idCatgory};

    my $model = Model::SaleMod->load( $args->{id} );
    $model->{priceAutogen} = $args->{priceAutogen};
    $model->save();

    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCatgory} );
}

sub admin_salemods_delete() {
    return OK unless $args->{id};
    my $sth = $db->prepare('delete from salemods where id = ?');
    $sth->execute( $args->{id} );
    my $sth = $db->prepare('delete from salerprices where idSaleMod = ?');
    $sth->execute( $args->{id} );
    return OK;
}

sub admin_salemods_set_base_for_mod() {
    return NOT_FOUND unless $args->{id};
    return NOT_FOUND unless $args->{baseId};
    my $model = Model::SaleMod->load( $args->{baseId} );
    $model->{baseId} = $args->{id};
    $model->save();

    my $bmodel = Model::SaleMod->load( $args->{id} );
    $bmodel->{baseId} = 1;
    $bmodel->save();
    redirect( '/cgi-bin/marketadmin?manage=salemods&action=show&id='
            . $args->{id} );
    return OK;
}

sub admin_salemods_show_prices() {
    return NOT_FOUND unless $args->{id};

    get_template(
        'backoffice/templates/salemods/prices' => $r,
        model => Model::SaleMod->load( $args->{id} ),
    );

    return OK;
}

sub admin_salemods_psearch_name() {
    my $srch = Core::Find->new();
    $args->{'frase'} =~ s/\-//g;
    $srch->{'frase'}    = $args->{'frase'};
    $srch->{'bfrase'}   = $args->{'brand'};
    $srch->{'cfrase'}   = $args->{'cat'};
    $srch->{'order_by'} = 'name';

    $srch->search_brand_name()    if $args->{'brand'};
    $srch->search_category_name() if $args->{'cat'};

    if ( $args->{'idBrand'} ) {
        push @{ $srch->{'brands'} }, $args->{'idBrand'};
    }
    if ( $args->{'idCategory'} ) {
        push @{ $srch->{'cats'} }, $args->{'idCategory'};
    }
    $srch->search_salemod_pname();
    my @buf;
    foreach ( @{ $srch->{'ids'} } ) {
        push @buf, Model::SaleMod->load($_);
    }
    get_template(
        'backoffice/templates/price/likeid' => $r,
        'likes'                             => \@buf,
        'numb'                              => $args->{'numb'},
    );
    return OK;
}

sub admin_salemods_bsearch_name() {

    use Search;

    get_template(
        'backoffice/templates/search_by_name' => $r,
        'list' => Search->new->search( $args->{frase} )
    );

    return OK;
}
####  ####
sub admin_positions_buyforcash() {
    get_template( 'backoffice/templates/positions/buyforcash' => $r, );
    return OK;
}

sub admin_positions_notsold() {

    get_template( 'backoffice/templates/positions/notsold' => $r, );
    return OK;
}

sub admin_positions_rejectreport() {

    get_template( 'backoffice/templates/rejected-report' => $r, );
    return OK;
}
sub admin_features {

    my $sth
        = $db->prepare(
        "select id from feature_groups where idCategory = ? and idParent = 0 and not deleted order by orderby"
        );
    $sth->execute( $args->{id} );

    my @buf = ();
    while ( my ($id) = $sth->fetchrow_array() ) {
        push @buf, Model::FeatureGroups->load($id);
    }

    get_template(
        'backoffice/templates/features/list' => $r,
        'list'                               => \@buf,
        'category' => Model::Category->load( $args->{id} ),
    );

    return OK;
}

sub admin_features_new {

    my $sth = $db->prepare("select distinct(measure) from feature_groups");
    $sth->execute();
    my $item;
    my @measure = ();

    while ( my ($measure) = $sth->fetchrow_array() ) {
        push @measure, $measure;
    }

    my @features = ();
    my $sth
        = $db->prepare(
        "select id from feature_groups where idParent = 0 and idCategory = ? "
        );
    $sth->execute( $args->{idCategory} );

    while ( my ($id) = $sth->fetchrow_array() ) {
        push @features, Model::FeatureGroups->load($id);
    }

    get_template(
        'backoffice/templates/features/new' => $r,
        'item'                              => $item,
        'autocomplite_measure'              => \@measure,
        'feature_groups'                    => \@features,
        'idCategory'                        => $args->{idCategory},
    );

    return OK;
}

sub admin_features_edit {
    my $item     = Model::FeatureGroups->load( $args->{id} );
    my @features = ();

    my $category = Model::Category->load( $item->{idCategory} );
    my $sth
        = $db->prepare(
        "select id from feature_groups where idParent = 0 and idCategory = ? "
        );
    $sth->execute( $item->{idCategory} );

    while ( my ($id) = $sth->fetchrow_array() ) {
        push @features, Model::FeatureGroups->load($id);
    }

    get_template(
        'backoffice/templates/features/edit' => $r,
        'item'                               => $item,
        'feature_groups'                     => \@features,
        'reload'                             => $args->{reload},
    );

    return OK;
}

sub admin_features_delete() {
    my $item = Model::FeatureGroups->load( $args->{id} );
    $item->delete();

    redirect( '/cgi-bin/marketadmin?manage=features&id=' . $args->{idc} );
}

sub admin_features_copy_from {
    if ( $args->{id} and $args->{from} ) {
        my $sth = $db->prepare(
            "replace into features(id,idSaleMod,idFeatureGroup,value)
                                select null,?,idFeatureGroup,value
                                from features
                                where idSaleMod = ?"
        );

        $sth->execute( $args->{id}, $args->{from} );
    }

    redirect( '/cgi-bin/marketadmin?manage=salemods&action=propertys&id='
            . $args->{id} );

    #return OK;
}

sub admin_features_post {

    if ( $args->{dbaction} eq 'update' ) {

        return &admin_features_edit() if $args->{id} eq $args->{idParent};
        my $item = Model::FeatureGroups->load( $args->{id} );
        my $key;
        foreach $key ( keys %{$args} ) {
            $item->{$key} = $args->{$key};
        }
        $item->save();
    }
    else {
        delete $args->{id};
        my $item = Model::FeatureGroups->new($args);
        $item->save();
        $args->{id} = $item->{id};
    }

    $args->{reload} = 1;

    &admin_features_edit();
}

sub admin_features_change_select() {
    foreach my $key ( keys %$args ) {
        my ( $ident, $idFeature ) = split( /_/, $key );
        if ( $ident eq 'feature' && $args->{idMod} && $idFeature ) {
            my $sth
                = $db->prepare(
                "replace features set idSaleMod = ?, idFeatureGroup = ?, value = ?"
                );
            $sth->execute( $args->{idMod}, $idFeature, $args->{$key} );
        }
    }
    redirect( '/cgi-bin/marketadmin?manage=salemods&action=propertys&id='
            . $args->{idMod} );
}
####  ####
sub admin_filter_delmodname() {
    my $obj = $user->session->get('filter_sales');
    delete $obj->{modname};
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_delmodprice() {
    my $obj = $user->session->get('filter_sales');
    delete $obj->{modprice};
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_setmodprice() {
    if ( $args->{minprice} or $args->{maxprice} ) {
        my $obj = $user->session->get('filter_sales');
        $obj->{modprice} = sprintf( '%d-%d', $args->{minprice} || 0,
            $args->{maxprice} || 0 );
        $user->session->set( 'filter_sales' => $obj );
        $user->session->save();
    }
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_delpropall() {
    my $obj = $user->session->get('filter_sales');
    $obj->{propertys} = undef;
    delete $obj->{propertys}
        unless keys %{ $obj->{propertys} };
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
}

sub admin_filter_delcat() {
    my $obj = $user->session->get('cat_id');
    $obj->{cat_id} = $args->{id};
    $user->session->set( 'cat_id' => $obj );
    $user->session->save();
    &admin_filter_delpropall();
    if ( $user->session->get('filter_sales') ) {
        if ( $user->session->get('filter_sales') ) {
            my $obj = $user->session->get('filter_sales');
            $obj->{brands} = undef;
            $user->session->set( 'filter_sales' => $obj );
            $user->session->save();
        }
    }
}

sub admin_filter_setmodname() {
    my $obj = $user->session->get('filter_sales');
    $obj->{modname} = $args->{value};
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_delbrand() {
    my $obj = $user->session->get('filter_sales');

    if ( $obj->{brands} ) {
        if ( $args->{id} == -1 ) {
            $obj->{brands} = undef;
        }
        else {
            my $buf = undef;
            foreach my $bid ( @{ $obj->{brands} } ) {
                push @$buf, $bid unless $bid == $args->{id};
            }
            $obj->{brands} = $buf;
        }
        $user->session->set( 'filter_sales' => $obj );
        $user->session->save();
    }
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_addbrand() {
    my $obj = $user->session->get('filter_sales');
    unless ( grep ( /^$args->{id}$/, @{ $obj->{brands} } ) ) {
        push @{ $obj->{brands} }, $args->{id};
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_addisPublic() {
    my $obj = $user->session->get('filter_sales');
    if ( !$obj->{isPublic} || $obj->{isPublic} == 0 ) {
        $obj->{isPublic} = '1';
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_delisPublic() {
    my $obj = $user->session->get('filter_sales');
    if ( $user->session->get('filter_sales')->{isPublic} == 1 ) {
        $obj->{isPublic} = '0';
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_addisImg() {
    my $obj = $user->session->get('filter_sales');
    if ( !$obj->{isImg} || $obj->{isImg} == 0 ) {
        $obj->{isImg} = '1';
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_delisImg() {
    my $obj = $user->session->get('filter_sales');
    if ( $user->session->get('filter_sales')->{isImg} == 1 ) {
        $obj->{isImg} = '0';
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_addSort {
    if ( !$user->session->get('sort') ) {
        my $obj  = $user->session->get('sort');
        my $sort = 'salemods.name';
        $obj->{sort}  = 'salemods.name';
        $obj->{limit} = '10';
        $user->session->set( 'sort' => $obj );
        $user->session->save();
    }
    if ( $user->session->get('sort') && $args->{sort} ) {
        my ( $ssort, $desc ) = split( /_/, $a->{sort} );
        my $obj = $user->session->get('sort');
        $obj->{sort} = $args->{sort};
        $user->session->set( 'sort' => $obj );
        $user->session->save();
    }
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_addisSimple() {
    my $obj = $user->session->get('filter_sales');
    if ( !$obj->{isSimple} || $obj->{isSimple} == 0 ) {
        $obj->{isSimple} = '1';
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filter_delisSimple() {
    my $obj = $user->session->get('filter_sales');
    if ( $user->session->get('filter_sales')->{isSimple} == 1 ) {
        $obj->{isSimple} = '0';
    }
    $user->session->set( 'filter_sales' => $obj );
    $user->session->save();
    redirect( '/cgi-bin/marketadmin?manage=sales&action=innerlist&id='
            . $args->{idCategory} );
}

sub admin_filters_generate {

    my $category = Model::Category->load( $args->{idCategory} );
    $category->generate_filters();
    &admin_filters();
}

sub admin_filters {
    my $sth
        = $db->prepare(
        "select id from feature_groups where searchable and public and idCategory = ?"
        );
    $sth->execute( $args->{'idCategory'} );
    use Model::Category;

    my @buf = ();
    while ( my ($id) = $sth->fetchrow_array() ) {
        push @buf, Model::FeatureGroups->load($id);
    }

    get_template(
        'backoffice/templates/features/filters/list' => $r,
        'list'                                       => \@buf,
        'category' => Model::Category->load( $args->{'idCategory'} )
    );
    return OK;
}

sub admin_filters_new {
    my $sth
        = $db->prepare(
        "select id from feature_groups where searchable and public and idCategory = ?"
        );
    $sth->execute( $args->{'idCategory'} );

    my @buf = ();
    while ( my ($id) = $sth->fetchrow_array() ) {
        push @buf, Model::FeatureGroups->load($id);
    }

    my $sth = $db->prepare("select id from feature_groups where id = ?");
    $sth->execute( $args->{'id'} );
    my ($feature) = $sth->fetchrow_array();
    use Model::FeatureGroups;
    $feature = Model::FeatureGroups->load($feature);

    my $sth = $db->prepare(
        "select distinct(value) from features where idFeatureGroup = ?");
    $sth->execute( $args->{'id'} );

    my @values = ();
    while ( my ($value) = $sth->fetchrow_array() ) {
        push @values, $value;
    }

    my $filter = ();

    get_template(
        'backoffice/templates/features/filters/edit' => $r,
        'list'                                       => \@buf,
        'id'                                         => $args->{id},
        'filter'                                     => $filter,
        'feature'                                    => $feature,
        'values'                                     => \@values,
        'show_variables' => $args->{show_variables},
    );
    return OK;
}

sub admin_filters_edit {
    my $sth = $db->prepare("select * from filters where id = ?");
    $sth->execute( $args->{id} );
    my $filter = $sth->fetchrow_hashref();

    my $sth = $db->prepare(
        "select distinct(value) from features where idFeatureGroup = ?");
    $sth->execute( $filter->{idParent} );

    $sth
        = $db->prepare(
        "select f.id from feature_groups f inner join filters fi on fi.idParent = f.id where fi.id = ?"
        );
    $sth->execute( $args->{id} );

    my ($feature) = $sth->fetchrow_array();
    use Model::FeatureGroups;
    $feature = Model::FeatureGroups->load($feature);

    my @values = ();
    while ( my ($value) = $sth->fetchrow_array() ) {
        push @values, $value;
    }

    get_template(
        'backoffice/templates/features/filters/edit' => $r,
        'filter'                                     => $filter,
        'values'                                     => \@values,
        'feature'                                    => $feature,
        'reload'                                     => $args->{reload},
    );
    return OK;
}

sub admin_filters_make {
    my $sth
        = $db->prepare(
        "select distinct(value) from features where idFeatureGroup = ? and value <> '' "
        );
    $sth->execute( $args->{id} );

    my @values = ();
    while ( my ($value) = $sth->fetchrow_array() ) {
        my $model = Model::Filter->new(
            {   idParent => $args->{id},
                title    => $value,
                rule     => 'eq',
                value    => $value,
            }
        );
        $model->save();
    }
    return OK;
}

sub admin_filters_delete {
    my $sth = $db->prepare("delete from filters where id = ? ");
    $sth->execute( $args->{id} );

    admin_filters();
}

sub admin_filters_oncat {
    my $sth
        = $db->prepare("update filters set onidCategory = ? where id = ? ");
    $sth->execute( $args->{onidCategory}, $args->{id} );
    admin_filters();
}

sub admin_filters_post {
    my $id = '';
    if ( $args->{title} and $args->{rule} and defined $args->{value} ) {
        if ( $args->{id} ) {
            $id = $args->{id};

            my $model = Model::Filter->load( $args->{id} );
            delete $args->{id};

            foreach my $key ( keys %{$args} ) {
                $model->{$key} = $args->{$key};
            }

            $model->save();
        }
        else {
            use Model::Filter;
            my $model = Model::Filter->new($args);
            $model->save();
            $id = $model->{id};
        }
    }

    $args           = ();
    $args->{id}     = $id;
    $args->{reload} = $id;

    return admin_filters_edit();
}
sub admin_salers() {
    my $sth
        = $db->prepare(
        'update salers s INNER JOIN users u ON s.name = u.name  set s.idUser = u.id where s.idUser = 0 and not s.deleted and s.name != "";'
        );
    $sth->execute();

    my @list;
    my $saler = undef;
    unless ( $args->{id} ) {
        my $sth = $db->prepare(
            'SELECT id FROM salers WHERE NOT deleted ORDER BY name');
        $sth->execute();
        while ( my ($id) = $sth->fetchrow_array ) {
            push @list, Model::Saler->load($id);
        }
    }
    else {
        $saler = Model::Saler->load( $args->{id} );
    }
    get_template(
        'backoffice/templates/salers/list' => $r,
        salers                             => \@list,
        saler                              => $saler,
    );
    return OK;
}

sub admin_salers_edit() {
    return OK unless $args->{id};
    my $top = { childs => Model::Category->list(0), };
    get_template(
        'backoffice/templates/salers/edit' => $r,
        saler => Model::Saler->load( $args->{id} ),
        top   => $top,
    );
    return OK;
}

sub admin_salers_post() {
    my $model = Model::Saler->new($args);

    if ( $args->{dbaction} eq 'insert' ) {
        my $sth
            = $db->prepare(
            'insert into users (name,password,type) values (?,"xyz","saler")'
            );
        $sth->execute( $args->{name} );
        my $sths = $db->prepare('select id from users where name = ? ');
        $sths->execute( $args->{name} );
        my $id = $sths->fetchrow_hashref;
        $model->{idUser} = $id;
        $model->setCategoryList($args);
        $model->save();
        $r->headers_out->add(
            Location => '/cgi-bin/marketadmin?manage=salers&action=edit&id='
                . $model->newid );
    }
    elsif ( $args->{dbaction} eq 'update' ) {
        $model->setCategoryList($args);
        $model->save();
        $model->vipSalerCat();
        $r->headers_out->add(
            Location => '/cgi-bin/marketadmin?manage=salers&action=edit&id='
                . $model->newid );
    }
    elsif ( $args->{dbaction} eq 'delete' ) {
        $model->delete();
    }
    return REDIRECT;
}

sub admin_salers_add() {
    my $top = { childs => Model::Category->list(0), };
    get_template(
        'backoffice/templates/salers/add' => $r,
        top                               => $top,
    );
    return OK;
}

sub admin_salers_category_report() {
    my $sth = $db->prepare(
        'select  c.id cid,
            c.name cname,
            s.name sname,
            count(sm.id) smcount,
            s.address saddress,
            s.phone sphone,
            s.managers smanagers
               FROM salers s INNER JOIN salerprices sp ON s.id = sp.idSaler
     INNER JOIN salemods sm ON sp.idSaleMod = sm.id
     INNER JOIN category c ON sm.idCategory = c.id
       GROUP BY c.id,s.id
       ORDER BY c.name, s.name;'
    );
    $sth->execute();
    my @buf;
    while ( my $item = $sth->fetchrow_hashref ) {
        push @buf, $item;
    }
    get_template(
        'backoffice/templates/salers/category_report' => $r,
        items                                         => \@buf,
    );
    return OK;
}

sub admin_salers_sign_all_salemod() {
    my $model = Model::Saler->load( $args->{'saler_id'} ) or return undef;

    $model->signAllSalemodsById();
    $model->setCategoryListBySalemods();

    $r->headers_out->add( Location => '/cgi-bin/marketadmin?manage=salers&id='
            . $model->{'id'} );
    return REDIRECT;
}

sub admin_salerprices() {
    return OK unless $args->{id};
    get_template(
        'backoffice/templates/salers/prices' => $r,
        saler    => Model::Saler->load( $args->{id} ),
        category => Model::Category->load( $args->{cid} ),
    );
    return OK;
}

sub admin_salerprices_post() {
    return OK unless $args->{id};

    Model::SalerPrices->spost($args);

    $r->headers_out->add(
              Location => '/cgi-bin/marketadmin?manage=salerprices&cid='
            . $args->{'cid'} . '&id='
            . $args->{'id'} );
    return REDIRECT;
}

sub admin_subprice() {
    if ( $args->{dbaction} eq 'update' ) {
        my $row = Model::SubPrice->load( $args->{'id'} );
        $row->{'min_price'}  = $args->{'min_price'};
        $row->{'max_price'}  = $args->{'max_price'};
        $row->{'value'}      = $args->{'value'};
        $row->{'percentage'} = $args->{'percentage'};
        $row->save();
    }
    elsif ( $args->{dbaction} eq 'save' ) {
        my $row = Model::SubPrice->new();
        $row->{'salers_id'} = '';
        foreach my $key ( keys %$args ) {
            next if ( $key !~ /^salers_id_(\d+)$/ );
            next if ( $args->{$key} eq '' );
            $row->{'salers_id'} .= $args->{$key} . ",";
        }
        if ( $row->{'salers_id'} ne '' ) {
            chop( $row->{'salers_id'} );
        }
        $row->{'cat_id'}     = $args->{'cat_id'};
        $row->{'brand_id'}   = $args->{'brand_id'};
        $row->{'min_price'}  = $args->{'min_price'};
        $row->{'max_price'}  = $args->{'max_price'};
        $row->{'value'}      = $args->{'value'};
        $row->{'percentage'} = $args->{'percentage'};
        $row->save();
    }
    elsif ( $args->{dbaction} eq 'delete' ) {

        #my $row = Model::SubPrice->load($args->{'id'});
        #$row->delete();
        my $sth = $db->prepare('DELETE FROM subprices WHERE id = ?');
        $sth->execute( $args->{'id'} );
    }
    elsif ( $args->{dbaction} eq 'copy' ) {
        my @list = split( /,/, $args->{'copy_to_cat_id'} );
        my $arg;
        foreach $arg (@list) {
            if ($arg) {
                my $sth
                    = $db->prepare(
                    'DELETE FROM subprices WHERE cat_id = ? and brand_id = "0"'
                    );
                $sth->execute($arg);

                my $sth
                    = $db->prepare(
                    'SELECT min_price,max_price,value,persentage FROM subprices WHERE cat_id = ? and brand_id = "0" ORDER BY min_price'
                    );
                $sth->execute( $args->{'cat_id'} );

                while ( my ( $min_price, $max_price, $value, $percentage )
                    = $sth->fetchrow_array )
                {
                    my $row = Model::SubPrice->new();
                    $row->{'cat_id'}     = $arg;
                    $row->{'min_price'}  = $min_price;
                    $row->{'max_price'}  = $max_price;
                    $row->{'value'}      = $value;
                    $row->{'percentage'} = $percentage;
                    $row->save();
                }
            }
        }
    }
    my $cat = Model::Category->load( $args->{cat_id} );
    get_template(
        'backoffice/templates/category/subprice' => $r,
        'list'     => Model::SubPrice->list( $args->{cat_id} ),
        'category' => $args->{cat_id},
        'brands'   => $cat->brandInCat(),
        'salers'   => $cat->cat_salers(),
    );
    return OK;
}
####  ####
sub admin_dfb_post() {
    if ( $args->{'dbaction'} eq 'update' ) {
        $args->{left_block} =~ s/\"/\'/g;
        $args->{centr_block} =~ s/\"/\'/g;
        $args->{right_block} =~ s/\"/\'/g;
        my $sth
            = $db->prepare(
            'replace into  default_footer_block (id,left_block,centr_block,right_block) values(?,?,?,?)'
            );
        $sth->execute(
            $args->{id},          $args->{left_block},
            $args->{centr_block}, $args->{right_block}
        );
    }
    if ( $args->{'dbaction'} eq 'list' ) {
        my $sth = $db->prepare("select * from default_footer_block");
        $sth->execute();

        my $dfb = $sth->fetchrow_hashref();
        get_template(
            'backoffice/templates/meta/dfb' => $r,
            'dfb'                           => $dfb,
        );

    }
    return OK;
}

sub admin_priceimport() {
    get_template(
        'backoffice/templates/price/index' => $r,
        list                               => Model::Saler->list(),
    );
    return OK;
}

sub admin_priceimport_tag() {
    my ( $saler, $t, $list );

    $saler = Model::Saler->load( $args->{'salers'} ) or return NOT_FOUND;
    if ( $args->{maketype} eq 'unfixcode' ) {
        $list = Core::PriceUpdate->list_of_fixed( $saler->{id} );
        $t    = 'backoffice/templates/price/unfixed_list';
    }
    elsif ( $args->{maketype} eq 'fixcode' ) {
        $t = 'backoffice/templates/price/start_bind';
    }
    elsif ( $args->{maketype} eq 'createnew' ) {
        $t = 'backoffice/templates/price/start_create';
    }
    else {
        $t = 'backoffice/templates/price/start_update';
        $saler->getBrandsDiscont();
    }
    get_template(
        $t    => $r,
        saler => $saler,
        list  => $list,
    );

    return OK;
}

sub admin_priceimport_parcer() {
    my $pu = Core::PriceUpdate->new();
    $pu->prepare_to_parsing( $r, $args );
    $pu->xls_to_csv();

    if ( $pu->{'pos_in_price'} > 0 ) {
        $pu->csv_to_mysql();
        $pu->get_info_for_list();

        if ( $args->{'maketype'} eq 'updateprice' ) {
            $pu->for_update();
            $pu->set_discont();
            $pu->set_saler_prices();
            $pu->set_saler_min_price();
            $pu->set_salemod_price();
            $pu->set_new_name();
            $pu->set_salemod_comment();
            $pu->set_statistic();
        }
        elsif ( $args->{'maketype'} eq 'downlistnew' ) {
            $pu->for_fix();
            $pu->create_list_of_new('end');
            exit;
        }
        elsif ( $args->{'maketype'} eq 'fixcode' ) {
            $pu->for_fix();
        }
        elsif ( $args->{'maketype'} eq 'createnew' ) {
            $pu->create_new();
            $pu->get_binded_product();
        }
    }

    my $t
        = $args->{maketype} eq 'fixcode'
        ? "backoffice/templates/price/binding"
        : '';
    $t
        = $args->{maketype} eq 'updateprice'
        ? "backoffice/templates/price/end_updating"
        : $t;
    $t
        = $args->{maketype} eq 'createnew'
        ? "backoffice/templates/price/end_binding"
        : $t;

    get_template(
        $t    => $r,
        items => $pu->get_info_for_fixcode(),
    );
    return OK;
}

sub admin_priceimport_likeid() {
    get_template(
        "backoffice/templates/price/likeid" => $r,
        likes => Core::PriceUpdate->get_liked_name( $args->{likes} ),
        rowid => $args->{rowid},
    );
    return OK;
}

sub admin_priceimport_fixcodes() {
    my $pu = Core::PriceUpdate->new();
    $pu->fixcodes($args);
    if ( $args->{'quit'} eq 'yes' ) {
        get_template(
            "backoffice/templates/price/end_binding" => $r,
            "items" => $pu->get_binded_product(),
            "clear" => $pu->drop_pu_table(),
        );
    }
    else {
        get_template(
            "backoffice/templates/price/binding" => $r,
            "items"                              => $pu->next_page_for_fix(),
        );
    }
    return OK;
}

sub admin_priceimport_addnewmod() {
    if ( $args->{'dbaction'} eq 'create' ) {
        return undef unless $args->{'idSaler'};
        return undef unless $args->{'code'};

        get_template(
            'backoffice/templates/price/addnewmod' => $r,
            'newmod' => Core::PriceUpdate->get_item(
                $args->{'code'}, $args->{'table'}
            ),
            'idSaler' => $args->{'idSaler'},
            'file'    => $args->{'table'},
        );
    }
    elsif ( $args->{'dbaction'} eq 'post' ) {
        my $tname    = $args->{'file'};
        my $model    = Model::SaleMod->new();
        my $category = Model::Category->load( $args->{'idCategory'} )
            or return undef;
        my $brand = Model::Brand->load( $args->{'idBrand'} ) or return undef;
        $model->{'name'} = $args->{'name'};
        $model->{'name'} = $brand->{'name'} . " " . $args->{'name'}
            if ( $args->{'append_brand_name'} eq 'append' );
        $model->{'alias'} = Base::Translate->translate( $model->{'name'} );

        my $old_mod = Model::SaleMod->load( $model->{'alias'}, 'alias' );
        if ( $old_mod->{'alias'} ) {
            print 'Product with this name alreadi exist ' . $model->errs;
        }
        else {
            $model->{'idBrand'}         = $args->{'idBrand'};
            $model->{'idCategory'}      = $args->{'idCategory'};
            $model->{'coment'}          = $args->{'coment'};
            $model->{'DescriptionFull'} = $args->{'DescriptionFull'};
            $model->{'priceAutogen'}    = $args->{'priceAutogen'};
            $model->{'isPublic'}        = $args->{'isPublic'};
            unless ( $model->save() ) {
                print 'Failed' . $model->errs;
            }
            my $saler = Model::Saler->load( $args->{'idSaler'} );
            $saler->addCategory( $args->{'idCategory'} );
            my $salerprices = Model::SalerPrices->new();
            $salerprices->{'idSaler'}   = $saler->{'id'};
            $salerprices->{'idSaleMod'} = $model->{'id'};
            $salerprices->{'uniqCode'}  = $args->{'code'};
            $salerprices->{'vip'}       = $saler->{'isVip'};
            $salerprices->save();
            my $sth
                = $db->prepare("update $tname set idMod = ? where code = ?");
            $sth->execute( $model->{'id'}, $args->{'code'} );
            get_template(
                "backoffice/templates/price/newmodinfo" => $r,
                "model"                                 => $model,
                "saler"                                 => $saler,
            );

        }
    }

    return OK;
}

sub admin_priceimport_unfix() {
    my $pos;
    foreach my $key ( keys %$args ) {
        my ($id) = ( $key =~ /^p_(\d+)$/ ) or next;
        $pos .= $id . ",";
    }
    chop($pos);
    Core::PriceUpdate->unfix_pos($pos);
    if ( $args->{'idMod'} ne '' ) {
        redirect(
            '/cgi-bin/marketadmin?manage=salemods&action=show&show=prices&id='
                . $args->{'idMod'} );
        return REDIRECT;
    }
    return OK;
}

sub admin_priceimport_apu_list() {
    my @buf;

    my $sth = $db->prepare('select * from salerprices_auto_update');
    $sth->execute();
    while ( my $item = $sth->fetchrow_hashref() ) {
        $item->{'saler'} = Model::Saler->load( $item->{'idSaler'} );
        push( @buf, $item );
    }
    get_template(
        'backoffice/templates/price/apu_list' => $r,
        'apus'                                => \@buf,
        'list'                                => Model::Saler->list(),
    );
    return OK;
}

sub admin_priceimport_apu_edit() {

    if ( $args->{'dbaction'} eq 'edit' ) {
        my $sth
            = $db->prepare(
            'update salerprices_auto_update set idSaler = ?,sender =?,subject=?,fileformat=?,filenam=?,fname=?,fcod=?,fprice=?,fstock=?,active=?,nostock=?,discont=?,del_all=?,page=?,idCurrency=? where id = ?'
            );
        $sth->execute(
            $args->{'idSaler'}, $args->{'sender'},
            $args->{'subject'}, $args->{'fileformat'},
            $args->{'filenam'}, $args->{'fname'} || '',
            $args->{'fcod'},    $args->{'fprice'},
            $args->{'fstock'} || '', $args->{'active'},
            $args->{'nostock'},    $args->{'discont'},
            $args->{'del_all'},    $args->{'page'},
            $args->{'idCurrency'}, $args->{'id'}
        );
    }
    elsif ( $args->{'dbaction'} eq 'insert' ) {
        my $sth
            = $db->prepare(
            'insert into salerprices_auto_update (idSaler,sender,subject,fileformat,filenam,fname,fcod,fprice,fstock,active,nostock,discont,del_all,page,idCurrency) value (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
            );
        $sth->execute(
            $args->{'idSaler'}, $args->{'sender'},
            $args->{'subject'}, $args->{'fileformat'},
            $args->{'filenam'}, $args->{'fname'},
            $args->{'fcod'},    $args->{'fprice'},
            $args->{'fstock'},  $args->{'active'},
            $args->{'nostock'}, $args->{'discont'},
            $args->{'del_all'}, $args->{'page'},
            $args->{'idCurrency'}
        );
    }
    elsif ( $args->{'dbaction'} eq 'delete' ) {
        my $sth = $db->prepare(
            'delete from salerprices_auto_update where id = ?');
        $sth->execute( $args->{'id'} );
    }

    &admin_priceimport_apu_list();
    return OK;
}

sub admin_priceimport_stat_update() {

    get_template( 'backoffice/templates/price/stat_update' => $r, );
    return OK;
}
####  ####
sub admin_comments() {

    get_template( 'backoffice/templates/comments' => $r, );
    return OK;
}

sub admin_comments_examine() {
    my $cat = Model::Category->load( $args->{'idCategory'} )
        if $args->{'tables'} eq 'salemods';
    my $cat = Model::APRSections->load( $args->{'idCategory'} )
        if $args->{'tables'} eq 'apr_pages';
    my $template = 'backoffice/templates/comments/salemods_exzimine';
    $template = 'backoffice/templates/comments/apr_pages_exzimine'
        if $args->{'tables'} eq 'apr_pages';
    $template = 'backoffice/templates/comments/parasite_exzimine'
        if $args->{'tables'} eq 'parasite';
    get_template(
        $template => $r,
        'list'    => Model::Comment->comments_for_category(
            $args->{'idCategory'}, $args->{'tables'}
        ),
        'idCategory' => $cat,
    );
    return OK;
}

sub admin_comments_edit() {
    foreach my $key ( keys %$args ) {
        my ($id) = ( $key =~ /^del_(\d+)$/ ) or next;
        my $com = Model::Comment->load($id);
        $com->delete;
    }
    foreach my $key ( keys %$args ) {
        my ($id) = ( $key =~ /^good_(\d+)$/ ) or next;
        my $Text = $args->{"t_$id"};
        my $com  = Model::Comment->load($id);
        my $sth  = $db->prepare(
            "update comment_text set comment = ? where id = ?");
        $sth->execute( $args->{"t_$id"}, $args->{"tid_$id"} );
        $com->{state} = 'confirmed';
        $com->save();
    }
}

sub admin_comments_answer() {
    if ( $args->{dbaction} eq 'insert' ) {
        my $comment = Model::Comment->new($args);
        $comment->save_text( $args->{text} );
        $comment->save();
    }
    else {
        my $com = Model::Comment->load( $args->{'id'} ) or return undef;
        get_template(
            'backoffice/templates/comments/answer' => $r,
            'question'                             => $com,
        );
    }
    return OK;
}
####  ####
sub admin_banners_product_type_list() {
    use Model::BannerProductTypes;
    get_template(
        'backoffice/templates/banners/product_type_list' => $r,
        'types' => Model::BannerProductTypes->list(),
    );

    return OK;
}

sub admin_banners_product_type() {
    use Model::BannerProductTypes;
    if ( $args->{'dbaction'} eq 'new' ) {
        get_template( 'backoffice/templates/banners/product_type_new' => $r,
        );
    }
    elsif ( $args->{'dbaction'} eq 'add' ) {
        my $type = Model::BannerProductTypes->new($args);
        $type->{'GalleryName'} = $args->{'name'};
        $type->{'alias'}       = $args->{'name'};
        $type->save();
        get_template(
            'backoffice/templates/banners/product_type_edit' => $r,
            'type'                                           => $type,
            'reload'                                         => 1,
        );
    }
    elsif ( $args->{'dbaction'} eq 'save' ) {
        my $type = Model::BannerProductTypes->new($args);
        $type->save();
        get_template(
            'backoffice/templates/banners/product_type_edit' => $r,
            'type'                                           => $type,
            'reload'                                         => 1,
        );
    }
    elsif ( $args->{'dbaction'} eq 'del' ) {
        my $type = Model::BannerProductTypes->new($args);
        $type->{'deleted'} = 1;
        $type->save();
        get_template(
            'backoffice/templates/banners/product_type_list' => $r,
            'reload'                                         => 1,
        );
    }
    elsif ( $args->{'dbaction'} eq 'gallery' ) {
        my $type = Model::BannerProductTypes->new($args);
        get_template(
            'backoffice/templates/banners/gallery' => $r,
            'type'                                 => $type,
            'reload'                               => 1,
        );
    }

    return OK;
}

sub admin_banners_type_mod() {
    use Model::BannerProducts;

    my $sth = $db->prepare("delete from bannerProducts where deleted");
    $sth->execute();

    my $prod = Model::BannerProducts->new($args);
    my $prod1 = $prod->get_by_type_and_mod() if $args->{'onse'} eq '1';
    $prod = $prod1 if $prod1->{'id'};
    if ( $args->{'dbaction'} eq 'add' ) {
        $prod->{'date_to'}  = "DATE_ADD(CURDATE(),INTERVAL 1 MONTH)";
        $prod->{'isPublic'} = "1";
    }
    elsif ( $args->{'dbaction'} eq 'period' ) {
        $prod->{'isPublic'} = "1";
        if ( $args->{'period'} eq 'week' ) {
            $prod->{'date_to'}
                = "DATE_ADD('" . $prod->{'date_to'} . "',INTERVAL 1 WEEK)";
        }
        elsif ( $args->{'period'} eq 'month' ) {
            $prod->{'date_to'}
                = "DATE_ADD('" . $prod->{'date_to'} . "',INTERVAL 1 MONTH)";
        }
        else { }
    }
    $prod->save();
    redirect( '/cgi-bin/marketadmin?manage=banners&action=show_products&idc='
            . $args->{'idc'} . '&id='
            . $prod->{'idType'} );

    return OK;
}

sub admin_banners_show_products() {
    return undef unless $args->{'id'};
    my $type = Model::BannerProductTypes->new($args);
    get_template(
        'backoffice/templates/banners/product_type_show' => $r,
        'type'                                           => $type,
        'idc'                                            => $args->{'idc'},
    );
    return OK;
}

sub admin_banners_for_category() {
    return undef unless $args->{'idCategory'};

    get_template(
        'backoffice/templates/category/product_banners' => $r,
        'category' => Model::Category->load( $args->{'idCategory'} ),
    );
    return OK;
}

sub admin_banners_add_group() {
    return 0 unless $args->{'idBanner'};
    use Core::Xls;
    my $xls = Core::Xls->new();
    $xls->get_xls($r);
    $xls->{'cols'} = [ 1, 2 ];
    my $res  = $xls->parce();
    my $prod = Model::BannerProducts->new();

    ####Misha AND Ivanb, kogda svodili ne znali 4to pravilnee. Misha skazal ostavim eto
    $prod->add_group( $res, %{$args} );

    ##### A bulo eto... Tak 4to ebash do konca
    ##### $prod->add_group($res,$args);

    &admin_banners_product_type_list();
}
####  ####
sub admin_competitors() {
    get_template( 'backoffice/templates/competitors/list' => $r, );
    return OK;
}

sub admin_competitors_add() {
    get_template( 'backoffice/templates/competitors/competitor_edit' => $r, );
    return OK;
}

sub admin_competitors_edit() {
    get_template(
        'backoffice/templates/competitors/competitor_edit' => $r,
        model => Model::Competitor->load( $args->{id} )
    );
    return OK;
}

sub admin_competitors_post() {
    my $model = Model::Competitor->new($args);
    $model->save();
    redirect(
        '/cgi-bin/marketadmin?manage=competitors&action=edit&reload=list&id='
            . $model->{id} );
}

sub admin_competitors_cat_list() {
    get_template(
        'backoffice/templates/competitors/cat_list' => $r,
        'model' => Model::Competitor->load( $args->{id} )
    );
    return OK;
}

sub admin_competitors_cat_edit() {
    get_template(
        'backoffice/templates/competitors/cat_edit' => $r,
        'model' => Model::Competitor::Parse->load( $args->{id} )
    );
    return OK;
}

sub admin_competitors_cat_parse() {
    my $model = Model::Competitor::Parse->load( $args->{id} )
        or return NOT_FOUND;
    get_template(
        'backoffice/templates/competitors/cat_parse' => $r,
        'model'                                      => $model->parse()
    );
    return OK;
}

sub admin_competitors_cat_add() {
    my $class = Model::Competitor::Parse->new($args);
    get_template( 'backoffice/templates/competitors/cat_edit' => $r );
    return OK;
}

sub admin_competitors_cat_del() {
    my $model = Model::Competitor::Parse->load( $args->{id} )
        or return NOT_FOUND;
    my $sth = $db->prepare("delete from competitors_parse where id = ?");
    $sth->execute( $args->{id} );
    redirect( '/cgi-bin/marketadmin?manage=competitors&action=cat_list&id='
            . $model->{comp_id} );
}

sub admin_competitors_cat_post() {
    my $model = Model::Competitor::Parse->new($args);
    $model->save();
    redirect( '/cgi-bin/marketadmin?manage=competitors&action=cat_edit&id='
            . $model->{id} );
}

sub admin_competitor_price_fixcode() {

    my $model = Model::Competitor::Price->load( $args->{id} );
    $model->{idMod} = $args->{idMod} || 0;
    $model->save();

    get_template(
        'backoffice/templates/competitors/fixcode' => $r,
        item                                       => $model,
    );
    return OK;
}

sub admin_competitors_update_unit_price() {
    foreach my $key ( keys %$args ) {

        my ($idMod) = ( $key =~ /^p(\d+)$/ );

        if ($idMod) {
            my $model
                = Model::Competitor::Price->update_unit_price( $args->{$key},
                $idMod, $args->{discont} );
        }

        next unless $idMod;
    }
    redirect(
        '/cgi-bin/marketadmin?manage=competitors&action=listprice_proc&id='
            . $args->{cat_id} );
}

sub admin_competitors_update_price_item() {
    my $model = Model::Competitor->load( $args->{id} );
    $model->update_price_item( $args->{item_id} );
    redirect( '/cgi-bin/marketadmin?manage=competitors&action=listprice&id='
            . $args->{id} );
}

sub admin_competitors_listprice() {
    my $model = Model::Competitor::Parse->load( $args->{id} )
        or return NOT_FOUND;

    get_template(
        'backoffice/templates/competitors/result' => $r,
        items                                     => $model->listprice_new(),
        model                                     => $model,
    );
    return OK;
}

sub admin_competitors_listprice_link() {
    my $model = Model::Competitor::Parse->load( $args->{id} )
        or return NOT_FOUND;

    get_template(
        'backoffice/templates/competitors/result_link' => $r,
        items => $model->listprice_link(),
        model => $model,
    );
    return OK;
}

sub admin_search_all(){
    my $template = $args->{template};
    get_template(
        "backoffice/templates/ajax/$template" => $r,
        );
    return OK;
}

####  ####

# sub admin_json_exlist() {
#   $db->do("
#            SELECT prod.id
#                AS id,

#                   prod.name
#                AS name,

#                   prod.price
#                AS price,

#                   brands.name
#                AS brand_name,

#                   cat.name
#                AS cat_name,

#                   cat_top.name
#                AS cat_top_name

#              FROM category
#                AS cat_top

#        INNER JOIN category
#                AS cat
#                ON cat_top.id = cat.idParent

#        INNER JOIN salemods
#                AS prod
#                ON prod.idCategory = cat.id

#        INNER JOIN brands
#                AS brands
#                ON brands.id = prod.idBrand

#          GROUP BY prod.id
#          ORDER BY cat_top.name, cat.name, brands.name, prod.name "
#   );

#   print $db->get_json();
#   return OK;
# }

# #### start ContentAdmin ####
# sub admin_content{
#     use Core::Content::Task;
#     get_template(
#         'backoffice/templates/content/menu' => $r,
#         'tasks' => Core::Content::Task->new(),
#     );
#     return OK;
# }
# sub admin_content_statistic(){
#     my @buf;
#     my $where ;
#     if ($args->{'id'}){ $where = "and cu.id = ".$args->{'id'};}
#     my $sth = $db->prepare("select ca.cdate,ca.count,cu.name,cu.id from content_archive as ca inner join content_users as cu on ca.idContent = cu.id where cu.deleted != 1 $where order by ca.cdate desc ");
#     $sth->execute();
#     while (my $item = $sth->fetchrow_hashref()){
#         push @buf,$item;
#     }
#     get_template(
#         'backoffice/templates/content/statistic' => $r,
#         'statistic' => \@buf,
#     );
#     return OK;
# }
# sub admin_content_statistic_monthly(){
#     my @buf;
#     my $where ;
#     if ($args->{'id'}){ $where = "and content_users.id = ".$args->{'id'};}
#     my $sth = $db->prepare("select name,DATE_FORMAT(cdate,'%m-20%y') as cdate,SUM(count) as count from content_archive,content_users where idContent = content_users.id and content_users.deleted != 1 $where group by idContent,DATE_FORMAT(cdate,'%m-20%y')");
#     $sth->execute();
#     while (my $item = $sth->fetchrow_hashref()){
#         push @buf,$item;
#     }
#     get_template(
#         'backoffice/templates/content/statistic' => $r,
#         'statistic' => \@buf,
#     );
#     return OK;
# }
# sub admin_content_show_tasks_new {

#     use Core::Content::Task;
#     get_template(
#         'backoffice/templates/content/list' => $r,
#         'list' => Core::Content::Task->list_new(),
#     );
#     return OK;
# }
# sub admin_content_show_tasks_rejected {

#     use Core::Content::Task;
#     get_template(
#         'backoffice/templates/content/list' => $r,
#         'list' => Core::Content::Task->list_rejected(),
#     );
#     return OK;
# }
# sub admin_content_show_tasks_done {

#     use Core::Content::Task;
#     get_template(
#         'backoffice/templates/content/list' => $r,
#         'list' => Core::Content::Task->list_done(),
#   'status' => 'done',
#     );
#     return OK;
# }
# sub admin_content_task_show {

#     use Core::Content::Task;
#     get_template(
#         'backoffice/templates/content/showtask' => $r,
#         'task' => Core::Content::Task->load($args->{id},'id'),
#     );
#     return OK;
# }
# sub admin_brands_clear_prices {
#     if($args->{idBrand}){
#         my $sth = $db->prepare("update salemods set price = 0 where idBrand = ? ");
#         $sth->execute($args->{idBrand});
#         redirect("/cgi-bin/marketadmin?manage=brands&action=edit&id=".$args->{idBrand});
#     }
# }
# sub admin_brands_clear_unbinded {
#     if($args->{idBrand}){
#         my $sth = $db->prepare("update salemods s left outer join salerprices sp on sp.idSaleMod = s.id set deleted = 1 where sp.idSaleMod is null and s.idBrand = ?");
#         $sth->execute($args->{idBrand});
#         $db->do('delete from salemods where deleted');
#         redirect("/cgi-bin/marketadmin?manage=brands&action=edit&id=".$args->{idBrand});
#     }
# }
# sub admin_content_task_post {

#     if ( $args->{state} eq 'confirm' ) {

#         my $task = Core::Content::Task->load($args->{id},'id');
#         $task->{comment} = $args->{comment};

#         my $sth = $db->prepare("update salemods set Description = ?, DescriptionFull = ? ,name = ? where id = ? ");
#         $sth->execute($task->product->{Description}, $task->product->{DescriptionFull}, $task->product->{name},$task->{idSaleMod});

#         my $gpath = $cfg->{PATH}->{gallery};
#         my $smpath  = $task->product->{image};
#         my $tsmpath = $smpath;
#         $smpath =~ s/content\///g;

#         my $command = "mkdir -p $gpath/$smpath/";
#         system($command);
#         my $command = "cp -a $gpath/$tsmpath/* $gpath/$smpath/";
#         system($command);
#         my $command = "rm -f $gpath/$tsmpath/*";
#         system($command);
#         my $command = "rmdir $gpath/$tsmpath/";
#         system($command);

#         my $sth = $db->prepare("update gallery set name = ? where name = ?");
#         $sth->execute($smpath,$tsmpath);

#         my $sth = $db->prepare("select count(*) from content_archive where cdate = CURDATE() and idContent = ?");
#         $sth->execute($task->{idContent});

#         my ($count) = $sth->fetchrow_array();
#         unless ($count) {
#             my $sth = $db->prepare("insert into content_archive(idContent,cdate,count) values(?,CURDATE(),0)");
#             $sth->execute($task->{idContent});
#         }

#         my $sth = $db->prepare("update gallery set name = ? where name = ?");
#         $sth->execute($smpath,$tsmpath);

#         my $sth = $db->prepare("select count(*) from content_archive where cdate = CURDATE() and idContent = ?");
#         $sth->execute($task->{idContent});

#         my ($count) = $sth->fetchrow_array();
#         unless ($count) {
#             my $sth = $db->prepare("insert into content_archive(idContent,cdate,count) values(?,CURDATE(),0)");
#             $sth->execute($task->{idContent});
#         }

#         my $sth = $db->prepare(" update content_archive set count = count + 1 where idContent = ? and cdate = CURDATE()");
#         $sth->execute($task->{idContent});

#         $db->do("delete from content_salemods where id = ".$task->product->{id});
#         $db->do("delete from content_tasks where id = ".$task->{id});

#         return OK;
#     }
#     elsif ( $args->{state} eq 'reject') {

#         my $task = Core::Content::Task->load($args->{id},'id');
#         $task->{state} = 'reject';
#         $task->{comment} = $args->{comment};
#         $task->save();

#         $r->headers_out->set(Location => $r->headers_in->{Referer});
#         return REDIRECT;
#     }
#     elsif ( $args->{state} eq 'new') {

#         my $task = Core::Content::Task->load($args->{id},'id');
#         $task->{state} = 'new';
#         $task->{comment} = $args->{comment};
#         $task->save();

#         $r->headers_out->set(Location => $r->headers_in->{Referer});
#         return REDIRECT;
#     }
#     else {

#         $r->headers_out->set(Location => $r->headers_in->{Referer});
#         return REDIRECT;
#     }
# }
# sub admin_content_maketasks {
#     foreach my $ar (keys %$args){
#         if (($ar =~ /^\d+$/) && ($args->{$ar} =~ /^\d+$/)){

#             my $content = Model::Content::User->load($args->{$ar});
#             my $product = Model::SaleMod->load($ar);
#             my $comment = $args->{"c_$ar"};

#             if ($content && $product){
#                 Model::Content::Task->makeTask($content,$product,$comment);
#             }
#         }
#     }
#     $r->headers_out->set(Location => $r->headers_in->{Referer});
#     return REDIRECT;
# }
# sub admin_content_users(){

#     get_template(
#         'backoffice/templates/content/users' => $r,
#         'users' => Model::Content::User->list(),
#     );
#     return OK;
# }
# sub admin_content_user(){
#     if ($args->{'dbaction'} eq 'insert'){
#         my $content = Model::Content::User->new($args);
#         if ($content->checkEmail()){
#             get_template('backoffice/templates/content/user_add' => $r, 'error' => 1,);
#             return OK;
#         }
#         $content->{'active'} = 1;
#         $content->{'password'} = $content->generatePassword();
#         $content->save();
#         $content->sendPasswordMessage();
#     }
#     elsif ($args->{'dbaction'} eq 'update'){
#         my $content = Model::Content::User->new($args);
#         $content->save();
#     }
#     elsif ($args->{'dbaction'} eq 'edit'){
#         get_template('backoffice/templates/content/user_edit' => $r, 'content' => Model::Content::User->load($args->{'id'}),);
#     }
#     else{
#         get_template('backoffice/templates/content/user_add' => $r,);
#     }
#     return OK;
# }
# sub admin_content_group_task_post {
#     foreach my $key (keys %$args){
#         if ($key =~ /^do_(\d+)$/){
#             $args->{id} = $1;
#             $args->{state} = 'confirm';
#             $args->{comment} = 'auto confirm';
#             &admin_content_task_post();
#         }
#         if ($key =~ /^del_(\d+)$/){
#             my $task = Core::Content::Task->load($1,'id');
#             $db->do("delete from content_salemods where id = ".$task->product->{id});
#             $db->do("delete from content_tasks where id = ".$task->{id});
#         }
#     }
#     $r->headers_out->set(Location => $r->headers_in->{Referer});
#     return REDIRECT;
# }
# sub admin_content_change_content_user{
#     if ($args->{sender} && $args->{reciver}){
#         my $sth = $db->prepare('update content_tasks set idContent = ? where idContent = ? and state = "new";');
#         $sth->execute($args->{reciver},$args->{sender});
#     }
#     return OK;
# }
# #### start ContentAdmin ####

1;

