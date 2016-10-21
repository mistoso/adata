package Model::APRTypesSettings;
use Model;
use Core::DB;
our @ISA = qw/Model/;

sub db_table() {'apr_types_settings'};
sub db_columns() {qw/id idType showKind showImgKind showInFrame sortTFrame sortBFrame sortOnPage limitRowsPages deleted/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

1;


