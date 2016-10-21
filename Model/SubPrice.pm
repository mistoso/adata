package Model::SubPrice;
use warnings;
use strict;

use Model;
use Model::Brand;
use Core::DB;
use Data::Dumper;
use Core::User;

our @ISA = qw/Model/;

sub db_table() {'subprices'};
sub db_columns() { qw/id cat_id brand_id salers_id min_price max_price value active percentage/};
sub db_indexes() {qw/id cat_id/};

sub list(){
    my ( $class, $category ) = @_;
    my $sth = $db->prepare("select s.*,b.name from subprices as s left join brands as b on s.brand_id = b.id where s.cat_id = ? order by s.brand_id,s.min_price");
    $sth->execute($category);
    my @buffer;
    while(my $item = $sth->fetchrow_hashref()){
        if ($item->{'salers_id'} ne ''){
            my $sth = $db->prepare("select name from salers where id in ($item->{'salers_id'})");
            $sth->execute();
            while (my ($name) = $sth->fetchrow_array()){
                push @{$item->{'salers_name'}},$name;
            }
        }
        push @buffer,$item;
    }
    return \@buffer;
}

sub _check_write_permissions(){
return 1;
}

sub _check_columns_values(){
    return 1;
}

1;
