package Model::Office::Phones;
use Model;
use DB;
use Core::User;
our @ISA = qw/Model/;

sub db_table() {'officePhones'};
sub db_columns() {qw/id idOffice code phone isPublic front operatorImg/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

1;
