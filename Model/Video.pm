package Model::Video;
use Model;

our @ISA = qw/Model/;

sub db_table() {'video'};
sub db_columns() {qw/id table_name idTable object deleted/};
sub db_indexes() {qw/id/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};
1;
