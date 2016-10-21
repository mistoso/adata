package Model::Meta::Url;
use warnings;
use strict;
use Model;
use DB;

our @ISA = qw/Model/;
sub db_table() {'meta_url'};
sub db_columns(){ qw/id url title description keywords h1 f_block_left s_block/};


sub list(){
    my $self = shift;

    my $sth = $db->prepare('SELECT id FROM meta_url WHERE NOT deleted');
    $sth->execute();
    my @buf;
    while (my ($id) = $sth->fetchrow_array){
        push @buf, Model::Meta::Url->load($id);
    }

    return \@buf;
}

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

1;

