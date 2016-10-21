package Model::FeatureGroups;
use warnings;
use strict;
use Model;
use Core::DB;
use Data::Dumper;
use Model::Feature;


our @ISA = qw/Model/;
sub db_table() {'feature_groups'};
sub db_columns(){ qw/id idCategory idParent name type measure orderby searchable public deleted/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub category {
    my $self = shift;
    return Model::Category->load($self->{idCategory});
}

sub is_parent {
    my $self = shift;
    return $self->{idParent} ? 0:1;
}

sub filters {
    my $self = shift;
    my $sth = $db->prepare("select * from filters where idParent = ? order by orderby");
    $sth->execute($self->{id});
    my @buf = ();

    while( my  $item = $sth->fetchrow_hashref()) {
        push @buf, $item; 
    }

    return \@buf;
}

sub list_active_main {
    my $self = shift;
    my $idCategory = shift;

    my $sth = $db->prepare("select id from feature_groups where idCategory = ? and idParent = 0 and public = 1 order by orderby");
    $sth->execute($idCategory);

    my @buf = ();
    while( my ($id) = $sth->fetchrow_array()) {
        push @buf, Model::FeatureGroups->load($id);
    }   

    return \@buf;
}

sub childs {
    my $self = shift;

    my $sth = $db->prepare("select id from feature_groups where idCategory = ? and idParent = ? and not deleted order by orderby");
    $sth->execute($self->{idCategory},$self->{id});

    my @buf = ();
    while( my ($id) = $sth->fetchrow_array()) {
        push @buf, Model::FeatureGroups->load($id);
    }   

    return \@buf;
}

sub childs_active {
    my $self = shift;

    my $sth = $db->prepare("select id from feature_groups where idCategory = ? and idParent = ? and public = 1 order by orderby");
    $sth->execute($self->{idCategory}, $self->{id});

    my @buf = ();
    while( my ($id) = $sth->fetchrow_array()) {
        push @buf, Model::FeatureGroups->load($id);
    }

    return \@buf;
}

1;
