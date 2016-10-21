package Base::Exception;

use base qw(Error);
use overload ('""' => 'stringify');
###############################################################################
sub new {
        my $this = shift;
        my $text = "" . shift;
        my @args = ();

        local $Error::Depth = $Error::Depth + 1;
        local $Error::Debug = 1;

        $this->SUPER::new(-text => $text, @args);
}
###############################################################################
1;

###############################################################################
package SQL::Exception;
	
	use base qw(Base::Exception);
1;

package StTemplate::Exception;

	use base qw(Base::Exception);
1;

package Session::Exception;

	use base qw(Base::Exception);
1;
###############################################################################
