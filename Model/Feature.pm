package Model::Feature;

use warnings;
use strict;
use Model;
use Core::DB;
use Data::Dumper;
use Model::FeatureGroups;

our @ISA = qw/Model/;
sub db_table() {'features'};
sub db_columns() { qw/id idSaleMod idFeatureGroup value/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub group() {
    my $self = shift; 
    return Model::FeatureGroups->load($self->{idFeatureGroup});
}

sub list {
    my $self = shift;
    my $id   = shift;
    my $sth = $db->prepare("select id from features where idSaleMod = ?");
    $sth->execute($id);
    my @buf = ();
    while ( my ($id) = $sth->fetchrow_array()){ 
  	  push (@buf, Model::Feature->load($id)); 
  	}
    return @buf;
}

1;
