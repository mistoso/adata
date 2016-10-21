package Core::APU;

use Core::User;
use Data::Dumper;
use Model::SaleMod;
use DB;
use Core::PriceUpdate;

sub new (){
    my $class = shift;
    my $id = shift;
    my $filename = shift;
    
    my $csth = $db->prepare('select * from salerprices_auto_update where id= ? ');
    $csth->execute($id);
    my $self = $csth->fetchrow_hashref();

    $self->{'attached_file'} = $filename;
	$self->{'maketype'} = 'updateprice';

    my $self = bless $self, $class;
    
    return $self;
}

sub prepare_to_apu (){
    my $self = shift;

    $self->{'file'} = "pu_".$self->{'idSaler'}."_".time;

    $self->{'attached_file'} =~ /(\.{1}(xls|zip|csv|xlsb))/is;

    my $file = $`;
    my $type = $1;

    $file = $self->{'filenam'} if  $self->{'filenam'} ;

    $self->{'attached_file'} =~ s/\s/\\ /g;

    if ($type eq '.zip'){
        system("cd /tmp/attached_prices/; unzip ".$self->{'attached_file'}.";rm -f ".$self->{'attached_file'} );
        $self->{'attached_file'} = "/tmp/attached_prices/".$file.".".$self->{'fileformat'};
    } elsif ($type eq '.xls'){
        $self->{'attached_file'} = "/tmp/attached_prices/".$file.".".$self->{'fileformat'};
    } elsif ($type eq '.xlsb'){
        $self->{'attached_file'} = "/tmp/attached_prices/".$file.".".$self->{'fileformat'};
    } elsif ($type eq '.csv'){
        $self->{'attached_file'} = "/tmp/attached_prices/".$file.".".$self->{'fileformat'};
        #print $self->{'attached_file'}."\n";
    }
    return OK;
}

sub do_apu(){
	my $self = shift;

	my $pu = Core::PriceUpdate->new();

	map { $pu->{ $_ } = $self->{ $_ } } keys %{ $self };

	$pu->xls_to_csv() if $self->{'fileformat'} eq 'xls';
	$pu->xls_to_csv() if $self->{'fileformat'} eq 'xlsb';
	$pu->csv_to_csv() if $self->{'fileformat'} eq 'csv';

	$pu->csv_to_mysql();
	$pu->get_info_for_list();

	$pu->create_new_gala();# osobenno eta chudo funkciya
	$pu->set_new_name();
	#print Dumper($pu);

	$pu->for_update();
	$pu->set_discont();
	$pu->set_saler_prices();
	$pu->set_saler_min_price();
	$pu->set_salemod_price();
	$pu->set_statistic();
	$self->{'log'} .= $pu->{'log'};
	return OK;
}

1;
