package Core::User;

use strict;
use warnings;

use Core::DB;
use Core::Gallery;

use CGI qw/cookie/;

use Model;

use Core::Session;
use Cfg;

our @ISA = qw/Model/;

use Data::Dumper;
use Logger;


sub db_table() { 'users' } 
sub db_columns() { qw/id name password type userType keySession email firstName  middleName lastName icq passCode passNumber group updated deleted/}


sub exlist(){
    my $args = shift;

    my $result = ModelList->new('Core::User',$args->{page},50);

    $result->filter( email  => $args->{email} ) 		if $args->{email};
    $result->filter( id => $args->{id} ) 				if $args->{id};
    $result->like( lastName => $args->{lastName}.'%') 	if $args->{lastName};
    $result->order('updated');
    $result->load();
    return $result;
}




sub groups(){ my $self = shift; return split(',',$self->{type});
}

sub isInGroup(){ my $self = shift; foreach my $group ($self->groups){ foreach my $igroup(@_){ return 1 if $group eq $igroup; } }  return 0;
}

sub fullPhone(){
    my $self = shift;
    return 'no';
}

sub fullName(){
    my $self = shift;
    return 1;
}

sub fname(){
    my $self = shift;
    return $self->{lastName}
	? ( $self->{firstName} and $self->{middleName} )  ? $self->{lastName}.' '. $self->{firstName}. '.' . $self->{middleName}.'.'  
	: $self->{lastName} : $self->{firstName} ? $self->{firstName} . sprintf(' %s-%s',$self->{cMobilePhone} || '', $self->{MobilePhone} || '') : $self->{name};

    if ($self->{lastName}){
	if ($self->{firstName} and $self->{middleName}){ 
			return $self->{lastName}.' '.$self->{firstName} . '.' . $self->{middleName}.'.';
	}else{
        return $self->{lastName};
    }
    }else{
    return $self->{name};
    }
}

sub current(){
    my $class = shift;

    my $path_info   = $ENV{PATH_INFO};
    my $script_name = $ENV{SCRIPT_NAME};

    if ( 	
		( $ENV{PATH_INFO}   and ($ENV{PATH_INFO}   =~ /^\/marketadmin$/)) 
	    or
		( $ENV{SCRIPT_NAME} and ($ENV{SCRIPT_NAME} =~ /marketadmin$/))
	)  
	{
    	    my ( $name, undef, undef, undef, undef ) = split /:/, cookie('Apache2::AuthCookieDBI_SecureArea') if cookie('Apache2::AuthCookieDBI_SecureArea'); 
	    return &load($class,$name,'name') if $name;
	}
    use Core::Guest;
    return Core::Guest->new();
}

sub load(){
    my ($class,$value,$column) = @_;
    $column ||= 'id';
    my $self;
#    unless($self = &_fetch_from_cache){
    $self = &_fetch_from_db($class,$column,$value);
#   }
}

sub _fetch_from_db(){
    my ($class, $column, $value) = @_;
    	return undef unless $value;

    my $sth = $db->prepare("SELECT * FROM users WHERE $column = ?") ;
    $sth->execute( $value );

    my $self = $sth->fetchrow_hashref;
    bless $self,$class;
#    $self->{sessionObj} = $self->session;
    return $self;
}

sub _fetch_from_cache(){
    return undef;
}

sub type(){
    my $self = shift;
    unless ($self->{_type}){
    	my $sth = $db->prepare('SELECT * FROM usertypes WHERE type = ?');
    	$sth->execute($self->{type});
    	$self->{_type} = $sth->fetchrow_hashref();
    }

    return $self->{_type};
}

sub contentlist(){
    my $self = shift;
    #return undef unless $self->{_type}->{type} =~ m/content/;
    unless ($self->{_contentlist}){
        my $sth = $db->prepare('SELECT * FROM content_users WHERE active = 1');
        $sth->execute();
        my @buf;
        while ( my $v = $sth->fetchrow_hashref){
            push @buf,$v;
        }
        $self->{_contentlist} = \@buf;
    }
    return $self->{_contentlist};
}



sub types(){
    my $self = shift;

    $self->{_types} ||= Core::User::Type->list();
}

sub _check_write_permissions() {1}
sub _check_columns_values()    { my $self = shift; $self->{name} ||= 'user'.int(rand(9999999)); return 1; }

sub _check_columns_values(){
    my $self = shift;
    return 1;
}
sub set(){
    my ($self,$args) = @_;

    foreach my $col ($self->db_columns()){
	$self->{$col} = $args->{$col} if defined $args->{$col};
    }
}

sub Error(){
    my ($class,$e) = @_; $e ||= $class; warn "Core::User $e"; return 0;
}

sub getgroup(){
    my ( $self, $type ) = @_;

    my @r    = ();
    my $sth  = $db->prepare('SELECT id FROM users WHERE FIND_IN_SET(?, type) ORDER BY lastName, name'); $sth->execute($type);
    while (my ($id) = $sth->fetchrow_array){ push @r,Core::User->load($id); }
    return \@r;

}

sub sessionObj(){
    my $self = shift; return $self->session;
}

sub session(){
    my $self = shift; $self->{_session} ||= Core::Session->instance();
}

sub workingList(){
    my $self = shift;

    my $sth = $db->prepare('SELECT id FROM users WHERE type NOT IN (\'saler\',\'user\') ORDER BY type');

    $sth->execute();
    my @buf;
    while( my ($id) = $sth->fetchrow_array){
	push @buf, Core::User->load($id);
    }

    return \@buf;
}

sub getEmployList(){
    my $self = shift;

    unless ($self->{_employ}){
	my $sth = $db->prepare('SELECT id FROM users WHERE type IN (\'manager\',\'coordinator\',\'root\') ORDER by type');
	$sth->execute();
	while (my ($id) = $sth->fetchrow_array){
    	    push @{$self->{_employ}}, Core::User->load($id);
	}
    }

    return $self->{_employ};
}


package Core::User::Type;
use Model; our @ISA = qw/Model/;

sub db_table(){'usertypes'};
sub db_columns() {qw/ type description/};


1;

