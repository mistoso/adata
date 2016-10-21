package Sessions::Ses;

use strict;

use Apache::Session::Flex;
use base qw(Apache::Session::Flex);

$Session::VERSION = 0.01;

sub new
{
    my($class, $id, @args) = @_;
    my $self;

    eval
    {
        $self = $class->TIEHASH($id, (ref $args[0] ? $args[0] : {@args}));
    };

    Sessions::Ses->error($@) if $@;

    return $self;
}

sub session_id  {shift->FETCH('_session_id')}
sub get         {shift->FETCH(@_)}
sub set         {shift->STORE(@_)}
sub remove      {shift->DELETE(@_)}
sub clear       {shift->CLEAR(@_)}
sub exists      {shift->EXISTS(@_)}
sub keys        {grep $_ ne '_session_id', keys %{shift->{data}}}
sub release     {undef($_[0])}
sub error
{
    $Session::ERROR = $_[1] if defined $_[1];
    return $Session::ERROR;
}

1;

__END__

