package Base::TiedTwoCount;

sub TIESCALAR { 
	my ( $class ) = @_;
	my $value = 1;
	bless \$value => $class;
}

sub STORE { ${ $_[0] } = $_[1]; }
sub FETCH { ${ $_[0] } =  ${ $_[0] } > 1 ? 1 : 2 ; }

1;
