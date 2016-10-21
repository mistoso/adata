package Core::DB;

BEGIN {

	use Exporter();	
	our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );        

	@ISA 		= qw(Exporter); 
	@EXPORT 	= qw($db); 
	@EXPORT_OK 	= qw( ); 
	$VERSION 	= 1.00; 

	use Base::Mysql; 
	use Cfg;
	
	our $db = Base::Mysql->instance( $cfg->{DB} ); 

	$db->do("SET CHARSET utf8"); 
	$db->do("SET NAMES utf8");
#	$db->do("--local-infile=1");
	

}

END { 

}

1;
