package Entry::Winkelwagen;

#use locale;
#use POSIX qw(locale_h);
#setlocale(LC_CTYPE,"ru_UA.UTF-8");
use strict;

use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;
use Apache2::SubRequest;
use Apache2::RequestRec;

use Logger;
use DB;
use Tools;
use Core::Template qw/get_template/;
use Data::Dumper;
use Core::Session;

use Cfg;
use Clean;

use Core::Error;
use Core::Meta;
use Core::Mail;
use Model::SaleMod;
use Core;

### by ivan
use Model::NewOrders;
use Model::NewOrdersPositions;
### by ivan

use Core::Winkelwagen::Product;
use Core::Winkelwagen::Order;
#use Core::Client::Authentication;

use Core::Client::Form;

our $r;
our $s;
#our $user;

our $args;
our $directory;
our $page;
our $extension;

sub handler(){ 
    	$r = shift;
	$args = &Tools::get_request_params($r);
	$r->content_type('text/html');
	$s = Core::Session->instance(1);
#	$user = Core::User->current();
	Core::Meta->instance(1,$r->uri());
	$r->uri() =~ /^\/(\w+)?\//;
	$directory = $1;

	$r->uri() =~ /^\/(\w+)?\/(\w+)?\.(\w+)$/;
	$page = $2;
	$extension = $3;
	
	map { $args->{$_} = Clean->all($args->{$_}) } keys %{$args};

	$log->info("Cont::Winkelwagen: Got /$directory/$page $extension");

    no strict 'refs';
	if (exists &{"dispatcher_".$page}) {
		return &{"dispatcher_".$page}; 
	}
    use strict;
	return NOT_FOUND;
}

sub redirect($){
        my $href = shift;
		$s->save();
        $r->method('GET');
        $r->method_number(M_GET);
        $r->internal_redirect($href);
	exit;
}

sub dispatcher_index {
	$log->info("Cont::Winkelwagen: ".Core::Winkelwagen::Product->dumper());
	get_template( 
			'frontoffice/templates/winkelwagen' => $r,
			'step' => '1',
	);
	return OK;
}

sub dispatcher_step2 {

#	return $tmp if my $tmp = step_check(2);

#	redirect("/$directory/delivery.html") if $user->id() > 0;

	get_template( 
			'frontoffice/templates/winkelwagen' => $r,
			'step' => '2',
			'error' => Core::Error->new(),
	);
	return OK;
}

sub dispatcher_amount {
	foreach my $key (keys %{$args})	{
		$log->info("Cont::Winkelwagen: For profuct id $key iset amount ".$args->{$key});	
		Core::Winkelwagen::Product->change($key,$args->{$key}) if ($args->{$key} > 0);
		Core::Winkelwagen::Product->delete($key) if ($args->{$key} < 1);
	}
	
	redirect("/$directory/index.html");	
	
    return OK;
}

sub dispatcher_quick_order(){

#    return $tmp if my $tmp = step_check(2);

    my $quick_orders;

	if ($args->{'delivery'}) {
	    $args->{comment} = $args->{'delivery'}." ".$args->{'comment'};
	}

	$args->{'comment'} = $args->{'email'}."  ".$args->{'comment'};

    if (keys %{$args} > 0) {
	Core::Client::Form->checkRequiredQuickOrderFields($args);

	my $buf = Core::Client::Form->getQuickOrderFields($args);
#	    print 'BUF->'.Dumper($buf);
#	    print 'err->'.Dumper(Core::Error->dumper());

	if (not Core::Error->error()){

    	    $buf->{createDate}    = 'NOW()';
    	    $buf->{currencyValue} = Model::Currency->usd_currency();
	    
	    $quick_orders = Model::NewOrders->new($buf);
	    $quick_orders->save();

	    foreach (@{Core::Winkelwagen::Product->getAll()}) {
		my $orders_positions;

		$orders_positions->{idOrder}    = $quick_orders->{id};
		$orders_positions->{state}      = "new";
		$orders_positions->{idMod}      = $_->{product}->{id};
		$orders_positions->{price}      = $_->{product}->{price};
		$orders_positions->{createDate} = 'NOW()';
		$orders_positions->{count}      = $_->{count};

		my $model = Model::NewOrdersPositions->new($orders_positions);
		$model->save();
        }

        my %tst;
        my %header;
        my %mvalue;

        my $office = Core->office();

	$buf->{'subject'} 	= 'Quick order';
        $buf->{'to'} 		= $office->{'email'}.',misha.burak@bigmir.net';
	$buf->{products} 	= Core::winkelwagenProducts();
	Sendmail('quick_order',$buf);
	###########################################

	Core::Winkelwagen::Product->deleteAll();

#        use Model::APRPages;
        
	get_template(
            'frontoffice/templates/winkelwagen' => $r,
            'step' => 'quick_thnx',
            'order' => $quick_orders,
        );
        return OK;
        }
    }

    get_template(
        'frontoffice/templates/winkelwagen'  => $r,
        'step'         => '1',
        'error'         => Core::Error->new(),
    );
    return OK;
}

sub dispatcher_quick_thnx {
    get_template(
        'frontoffice/templates/winkelwagen' => $r,
        'step' => 'quick_thnx',
    );
    return OK;			
}

sub dispatcher_add {
	my $redirect_path = '';

	if ($directory ne 'winkelwagen' and $page ne 'add') {
		$redirect_path  = "/".$directory."/".$page;
	}
	else {
		$redirect_path = '/winkelwagen/';
	}
	
	my $id = $args->{'salemod_to_add'};

	if (Core::Winkelwagen::Product->add($id,1)) {
		$log->info("Cont::Winkelwagen: Add ".Core::Winkelwagen::Product->dumper()." and redirect to $redirect_path");
	}

	else {
		$log->info("Cont::Winkelwagen: Cannot add product $id, redirect to $redirect_path");
	}

    if ($args->{'redirect'} ne ''){ 
        redirect("/".$args->{'redirect'}.".htm");
    }else{
        redirect($redirect_path);
    }
}
#--------------------------------------------------------------------------------------------
# dummi functions 
#--------------------------------------------------------------------------------------------
sub dispatcher_ {
	dispatcher_index();
}

sub dispatcher_step1 {
	dispatcher_();
}
#--------------------------------------------------------------------------------------------
# end
#--------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------
# subs 
#--------------------------------------------------------------------------------------------
sub step_check() {
	my $step = shift;
	my $return = '';

	#for step 3
    if ($step > 3){
        $return = 'delivery' if $s->get('delivery_address') eq '';
        $return = 'delivery' if $s->get('payment') eq '';
    }

	#for step delivery
	if ( $step > 2 ){
#		$return = 'step2' if $user->id() eq '0';
	}
	# for step 2
	if  ( $step > 1 ) {
		$return = 'index' unless (Core::Winkelwagen::Product->getAllSumm() > 0);
	}
	$log->info("Cont::Winkelwagen: Got return in step_check - ".$return) if $return;
	redirect("/$directory/$return.html") if $return; 
}
#--------------------------------------------------------------------------------------------
# end 
#--------------------------------------------------------------------------------------------

1;
