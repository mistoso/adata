package Model::Office::Schedule;
use Model;
use DB;
use Core::User;
our @ISA = qw/Model/;

sub db_table() {'officeSchedule'};
sub db_columns() {qw/id idOffice period tfrom tto isPublic/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

1;
