package Model::SalerPrices;

###################################### ivan from adata

use Model;
use Model::SaleMod;

our @ISA = qw/Model/;

sub db_table() {'salerprices'};
sub db_columns() { qw/id idSaler idSaleMod price instock stockComment uniqCode ignored idOperator updated vip/};

sub model(){
	my $self = shift; $self->{_model} ||= Model::SaleMod->load($self->{idSaleMod});
}

sub spost(){
    my $self = shift;
    my $arg = shift;
    foreach my $key (keys %$arg){
        my ($id) = ($key =~ /^new_(\d+)$/) or next;
        if (($arg->{"new_$id"} ne $arg->{"old_$id"}) && ($arg->{"new_$id"} =~ /^(\d+)$/)){	

			#### may be this part not important in this row  <-- && ( $arg->{"new_$id"} =~ /^(\d+)$/ ###MISHA
            my $salerprice = $self->load($id);   									
			#### there, like this...  my $mod = Model::SalerPrices->load($id); $salerprice->{'uniqCode'} &&= $arg->{"code_$id"}; $mod->{'price'} = $arg->{"new_$id"}; $salerprice->save();
            $salerprice->{'uniqCode'} = $arg->{"code_$id"} if $arg->{"code_$id"}; 	
			### May be this row must by like this -> $salerprice->{'uniqCode'} ||= $arg->{"code_$id"}; 
            $salerprice->{'price'} = $arg->{"new_$id"};
            $salerprice->save();
        }
    }
    
    return 1;
}

sub _check_columns_values(){1}
sub _check_write_permissions(){1}

1;

