package Core::Meta::Factory;

use strict;

sub init {
        my $class    = shift;
        my $type     = uc(shift);

        my $location = "Core/Meta/$type.pm";
        my $class    = "Core::Meta::$type";

        require $location;
        return $class->new(@_);
}

1;
