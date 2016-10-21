package Core::JSON;
use warnings; 
use strict; 
use DBI ();
use Carp ();


sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->_init(@_) || return ();
    return $self;
}

sub _init {
    my ( $self, $dbh ) = @_;
    
    eval {
        $self->{dbh} =  $dbh;
    } 
    or $@ && Carp::croak $@;
    if ( !$self->{dbh} ) {
        return ();
    }
    else {
        $self->{dbh}->{PrintError} = 0;
    }

    1;
}

sub do_select {
    my ( $self, $sql, $key_field, $hash_array ) = @_;
    
    if ($key_field) {
        eval { 
            $self->{data} = $self->{dbh}->selectall_hashref( $sql, $key_field ); 
        } 
        or $@ && Carp::croak $@;
        if ( $self->{dbh}->err ) { 
            Carp::carp $self->{dbh}->errstr; 
        }
        if ( $hash_array ) { 
            $self->{data} = [ values( %{ $self->{data} } ) ]; 
        }
    }
    else {
        eval { 
            $self->{data} = $self->{dbh}->selectall_arrayref($sql); 
        }
        or $@ && Carp::croak $@;
        if ( $self->{dbh}->err ) {
            Carp::carp $self->{dbh}->errstr;
        }
    }
    return $self;
}

sub do_sql {
    my ( $self, $sql ) = @_;
    eval { 
        $self->{dbh}->do($sql); 
    } 
    or $@ && Carp::croak $@;
    if ( $self->{dbh}->err ) {
        Carp::carp $self->{dbh}->errstr;
    }
    return $self;
}

sub has_data {
    my $self = shift;

    if ( ref $self->{data} ) {
        return 1;
    }
    
    return ();
}

sub get_json {
    my $self = shift;
    
    if ( $self->has_data ) {
		use JSON::Syck;
		$JSON::Syck::ImplicitUnicode = 1;
        return JSON::Syck::Dump( $self->{data} );
    }

    return ();

}

sub clear_data {
    my $self = shift;
    $self->{data} = ();
    1;
}

sub errstr {
    my $self = shift;
    
    if ( $self->{dbh} ) {
        return $self->{dbh}->errstr;
    }
    
    else {
        return ();
    }

}

sub err {
    my $self = shift;
    
    if ( $self->{dbh} ) {
        return $self->{dbh}->err;
    }
    
    else {
        return ();
    }

}

sub DESTROY {
    my $self = shift;
    
    if ( $self->{dbh} ) {
        $self->{dbh}->disconnect;
    }
    
    else {
        return ();
    }

}

1;

