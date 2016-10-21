package Model::GallerySrc;

use strict; 
use warnings;

use Model;  
our @ISA = qw/Model/;

sub db_table()   { 'gallery_src' };
sub db_columns() { qw/id src idGallery/ };
sub db_indexes() { qw/id src/ };

sub _check_columns_values() {1};
sub _check_write_permissions() {1}; 

1;

