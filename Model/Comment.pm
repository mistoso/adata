package Model::Comment;
use strict;
use Model;
use Core::DB;
use Model::Category;
use Model::SaleMod;
use Data::Dumper;
use Clean;
use Encode;
our @ISA = qw/Model/;


sub db_table() {'comments'};
sub db_columns() {qw/id tables idMod idText idCategory idBrand idParent state deleted updated name email mark phone/};
sub db_indexes() {qw/id idMod/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub subject(){
    my $self = shift;
    unless ($self->{subject}){
        $self->{subject} = Model::APRPages->load($self->{idMod}) if $self->{'tables'} eq 'apr_pages';
        $self->{subject} = Model::SaleMod->load($self->{idMod}) if $self->{'tables'} eq 'salemods';
    }
    return $self->{subject};
}

sub load(){
    my ($class,$value,$column) = @_;
    $column ||= 'id';
    return undef unless $value;
    my $self = ();
    my $sth = $db->prepare("select * from comments where ".$column." = ? and not deleted");
    $sth->execute($value);
    $self = $sth->fetchrow_hashref() or return &Model::Error('unable to load model');
    my $ctext = Model::Comment::Text->load($self->{'idText'});
    $self->{'text'} = $ctext->{'comment'};
    bless $self,$class;
    return $self;
}

sub save_text(){
    my $self = shift;
    my $text = shift;
    my $ncom;
    $ncom->{comment} = Clean->all($text);
    my $ctext = Model::Comment::Text->new($ncom);
    $ctext->save();
    $self->{'idText'} = $ctext->{'id'};
    return $self->{'idText'};
}

sub comments_for_mod(){
    my $self = shift;
    my $idm = shift;
	my $public = shift;
	my $where = ' and 1 ';
	if ($public == 'ok'){
		$where = ' and state = "confirmed" ';} 
    my @buf;
    my $sth = $db->prepare("select id from comments where idMod = ? and not deleted and tables = 'salemods' ".$where." order by updated desc");
    $sth->execute($idm);
    while ( my ($id) = $sth->fetchrow_array()){
        my $com = $self->load($id);
        push @buf,$com ;
    }
    return \@buf;
}

sub comments_for_category(){
    my $self = shift;
    my $value = shift;
    my $tables = shift;
    my @buf;
    my $sth = $db->prepare("select id from comments where idCategory = ? and not deleted and tables = ? order by updated desc ");
    $sth->execute($value,$tables);
    while (my ($id) = $sth->fetchrow_array()){
        my $com = Model::Comment->load($id);
        push @buf,$com ;
    }
    return \@buf;
}

sub new_comments_for_category(){
    my $self = shift;
    my $value = shift;
    my @buf;
    my $sth = $db->prepare("select id from comments where idCategory = ? and state= 'new' order by updated desc");
    $sth->execute($value);
    while (my ($id) = $sth->fetchrow_array()){
        my $com = Model::Comment->load($id);
        push @buf,$com ;
    }
    return \@buf;
}

sub answers(){
    my $self = shift;
    my @buf;
    my $sth = $db->prepare("select id from comments where idParent = ? order by updated desc");
    $sth->execute($self->{'id'});
    while (my ($id) = $sth->fetchrow_array()){
        my $com = Model::Comment->load($id);
        push @buf,$com ;
    }
    return \@buf;
}

sub comments_for(){
    my $self = shift;
    my $table = shift;
    my $idm = shift;
    my @buf;
    
    my $sth = $db->prepare("select id from comments where idMod = ? and tables = ? order by updated desc");
    $sth->execute($idm,$table);
    while (my ($id) = $sth->fetchrow_array()){
        my $com = Model::Comment->load($id);
        push @buf,$com ;
    }
    
    return \@buf;
}

sub last_comments(){
    my $self = shift;
    my $table = shift;
    my $cat = shift;
    my $brand = shift;
    my $limit = shift;
    my @buf;
    
    my $q = "select id from comments where state = 'confirmed' and not deleted";
    $q .= " and tables = '".$table."' "  if $table ne ''; 
    $q .= " and idCategory in (".$cat.") "  if $cat ne ''; 
    $q .= " and idBrand = ".$brand if $brand ne '';
    $q .= " order by updated desc ";
    $q .= "limit ".$limit if $limit ne '';
    my $sth = $db->prepare($q);
    $sth->execute();
    while (my ($id) = $sth->fetchrow_array()){
        my $com = Model::Comment->load($id);
        push @buf,$com ;
    }
    
    return \@buf;
}

package Model::Comment::Text;
use Model;
use Core::User;
use Core::Gallery;

our @ISA = qw/Model/;


sub db_table() {'comment_text'};
sub db_columns() {qw/id comment/};
sub db_indexes() {qw/id/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};


1;


