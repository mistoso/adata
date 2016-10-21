package Entry::Cpan;

use strict; 
use warnings;

use Apache2::Const qw/OK NOT_FOUND/;
use Apache2::RequestUtil ();

sub handler { my $r = shift; print cpan; return OK; }

1;

