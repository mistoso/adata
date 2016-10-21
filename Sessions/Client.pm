package Sessions::Client;

#use strict 'refs';

use Sessions::Ses;
use Apache2::Cookie;
use Apache2::SafePnotes;
use Apache::Session::Redis;

use Logger;

sub new() {
    my $class = shift;
    bless { request => shift }, $class;
}

sub build_session() {
    my $self = shift;
    my $j = Apache2::Cookie::Jar->new( $self->{request} );
    my ( undef, $key ) = split( /=/, $j->cookies('su') || '' );
    $key = $self->{request}->safe_pnotes('su') unless $key;
    $ENV{REDIS_SERVER} = '127.0.0.1:6379';
    my %session_args = (
        server    => '127.0.0.1:6379',
        Lock      => 'Null',
        Generate  => 'MD5',
        Store     => 'NoSQL',
        Driver    => 'Redis',
        Serialize => 'Base64',
    );
    my $s;
    unless ( $key and $s = Sessions::Ses->new( $key, %session_args ) ) {
        $s = Sessions::Ses->new( undef, %session_args )
            or die "Sessions::Client err: " . Sessions::Ses->error . "\n";
        $s->save();
        my $cookie = Apache2::Cookie->new(
            $self->{request},
            -name    => 'su',
            -value   => $s->session_id(),
            -path    => '/',
            -expires => '+8d'
        );

        $cookie->bake( $self->{request} );
        $self->{request}->safe_pnotes( su => $s->session_id() );
    }
    return $s;
}

sub ses() {
    my $self = shift;
    unless( $self->{_session} ) {
        $self->{_session} = $self->build_session;
    }
    return $self->{_session};
}


1;
