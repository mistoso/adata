package Model::Files;
use warnings;
use strict;
use Model;
use Core::DB;
our @ISA = qw/Model/;
sub db_table()   { 'files' };
sub db_columns() { qw/id name text deleted/ };
sub db_indexes() { qw/id/ };

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

1;
