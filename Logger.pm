package Logger;
use strict;

BEGIN {
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);        
	$VERSION     = 1.00;

	@ISA = qw(Exporter);
	@EXPORT = qw($log);

	unless (Log::Log4perl->initialized()) {
		use Cfg qw/$Logger/;
		use Log::Log4perl;
		Log::Log4perl::init_once( \$Logger );
    		our $log = Log::Log4perl::get_logger("Logger");
		$SIG{__WARN__} = sub { $log->warn(@_) };
		$SIG{__DIE__}  = sub {  };
	}
}

1;

