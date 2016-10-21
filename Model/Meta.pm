package Model::Meta;
use warnings;
use strict;
use Model;
use Core::DB;

our @ISA = qw/Model/;
sub db_table() {'meta'};
sub db_columns(){ qw/id what title description keywords f_block_left s_block/};


sub list(){
    my $self = shift;

    my $sth = $db->prepare('SELECT id FROM meta WHERE NOT deleted');
    $sth->execute();
    my @buf;
    while (my ($id) = $sth->fetchrow_array){
        push @buf, Model::Meta->load($id);
    }

    return \@buf;
}

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

1;

