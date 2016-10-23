package Core::Pager;
use strict;

use POSIX qw(ceil);
use Cfg;
use Core::Session;
    
sub new {
    my $class = shift;

    $class = ref $class if ref $class;
    my $self = bless {}, $class;

    my $page   = shift;
    my $onpage = shift;

    $self->calculate($page,$onpage);

    #boundary from current page to left and right

    $self->{boundary} = 5;

    $self;
}

sub calculate {
    my $self  = shift;
    my $page  = shift;
    my $limit = shift;

    my $offset = 0;
    my $begin  = 0;
    my $count = 100;
#    use Apache2::RequestUtil;
#    my $r = Apache2::RequestUtil->request();

#    use Sessions::Client;
#    my $s = Sessions::Client->new($r)->ses; ## $r is Required param

    my $s = Core::Session->instance(1);



    if ($limit =~ /^\d+$/) {

        unless ($cfg->{salemods_on_page}->{options}->{$limit}) {
            $limit = $cfg->{salemods_on_page}->{default}; 
            $begin = 0;
        }

        if ($s->get('salemods_on_page') ne $limit) {

            $s->set('salemods_on_page',$limit);
            $begin = 0;
            $s->save();
        }
    }
    unless ( $limit and $limit =~ /^\d+$/) {
        $limit = $s->get('salemods_on_page');
        $limit = $cfg->{salemods_on_page}->{default} unless $limit ;
    }

    unless ($begin) {
        if (($page =~ /^\d+$/) and ($page < 100000) and ($page > 0)) {
            $offset = ($page * $limit) - $limit; 
        }
        else {
            $offset = 0;
        }
    }
    else {
        $offset = 0;
    }

 

    $self->setOffset($offset + $limit);
    $self->setLimit($limit);
}

sub setOffset {
    my $self = shift;
    my $tmp = shift;

    $tmp = 1 if $tmp < 1; 
    $self->{offset} = $tmp;
}

sub setLimit {
    my $self = shift;
    my $tmp = shift;

    $tmp = 1 if $tmp < 1; 
    $self->{limit} = $tmp;
}

sub setMax {
    my $self = shift;
    my $tmp = shift;

    $tmp = 1 if $tmp < 1; 
    $self->{max} = $tmp;
}

sub getMinPageBoundary {
    my $self = shift;

    return ceil($self->{offset} / $self->{limit}) - $self->{boundary};
}

sub getOffset {
    my $self = shift;

    return ($self->{offset} - $self->{limit} );
}

sub getLimit {
    my $self = shift;

    return $self->{limit};
}

sub getMaxPageBoundary {
    my $self = shift;

    return ceil($self->{offset} / $self->{limit}) + $self->{boundary};
}

sub getCurrentPagesBoundary {
    my $self = shift;

    my $minb = $self->getMinPageBoundary();
    my $maxb = $self->getMaxPageBoundary();

    if ($minb < 1 ) {
        $maxb += ($minb * (-1));
        $minb = 1;
        $maxb += $minb;
    }

    if ($maxb > $self->getPagesCount()) {
        my $tmp = ($self->getPagesCount() - $maxb) * (-1);
        $minb -= $tmp;
        $maxb -= $tmp;
    }

    $minb = 1 if $minb < 1;

    my @buf = ();
    for ($minb .. $maxb) {
            push @buf,{ 
                'num'  => $_,
                'step' => $_ * $self->{limit},
                'cur'  => ($_ == $self->getCurrentPage() ? 1 : 0),
            };
    }
    use Data::Dumper;
    return @buf;
}

sub getPagesCount {
    my $self = shift;

    return ceil($self->{max} / $self->{limit});
}

sub getCurrentPage {
    my $self = shift;
    return ceil($self->{offset} / $self->{limit});
}

sub isFirst {
    my $self = shift;

    return 1 if $self->getCurrentPage() == 1;
    return 0;
}

sub isLast {
    my $self = shift;

    return 1 if $self->getCurrentPage == $self->getPagesCount();
    return 0;
}

sub isNeed {
    my $self = shift;

    return 1 if $self->{max} > $self->{limit};
    return 0;
}

1;
