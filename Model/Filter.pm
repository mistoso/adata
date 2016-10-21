package Model::Filter;
use warnings; use strict;
use Model;    our @ISA = qw/Model/;

sub db_table() {'filters'};
sub db_columns(){ qw/id idParent title rule value orderby onidCategory/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};


1;
