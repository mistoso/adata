package Crond::CheckMailForPriceUpdate;
#use strict;

sub new(){
	my $class = shift;
	
	my $this  = {
		lib_path => shift,
		log      => '',
	};

	return bless $this, $class;
}

sub log {
	my $this = shift;
	my $text = shift;

	$this->{log} .= $text."<br>";
}

sub execute {
	my $this = shift;
	use lib "$this->{lib_path}";
#--------------------------------------------------------------------
# Your code start ehre 
#--------------------------------------------------------------------
	
    
    use Core::DB;
	use FindBin qw/$Bin/;
    use Data::Dumper;
    use lib "$Bin/../lib";
    use Cfg;
    use Mail::POP3Client;
    use Mail::MboxParser::Mail;
    use MIME::Base64;
    use Encode;
    use Core::APU;

    my $path = '/tmp/attached_prices/'; my @apus; my $i;

    my $stha = $db->prepare('SELECT id, idSaler, sender, subject FROM salerprices_auto_update WHERE active = 1'); $stha->execute(); while ( my $apu = $stha->fetchrow_hashref ){ push @rules, $apu; }
    my $pop  = new Mail::POP3Client( USER => 'vash.price@gmail.com', PASSWORD => 'vash1auto', HOST => 'pop.gmail.com', USESSL   => true, ); $pop->Connect() >= 0 || die $pop->Message();

   for ( $i = 1; $i <= $pop->Count(); $i++ ) {

        my ( $from, $subject, $attach, $filename, $subj );

        my $msg = Mail::MboxParser::Mail->new( [ $pop->Head($i) ],[ $pop->Body($i) ] );
        
	$from    = $msg->from->{email};
        $subject = $msg->header->{subject};

        if ( $msg->from->{email}     =~ /^<(.+)>$/ )  			   { $from    = $1; }
	if ( $msg->header->{subject} =~ /^(=\?)(.+)(\?\ub\?)(.+)(\?=)$/ )  { $subject = decode( $2, decode_base64($4)); }

	my $mapping = $msg->get_attachments;

	for my $filename (keys %$mapping) { if ( $filename =~ /\.(xls|zip|xlsb)$/ ) { $attach = $filename; } }

	print "$from,$subject,$attach,\n";

	foreach my $rule (@rules){

            if ( (  ( $rule->{'sender'} eq $from ) || ( $rule->{'subject'} eq $subject ) ) && ( $attach ne '' ) ) {

                    my $store = $msg->store_all_attachments( path => $path, store_only => qr/\.(xls|zip|xlsb)$/i);

			my $apus = Core::APU->new( $rule->{'id'}, $attach );
                	$apus->prepare_to_apu();
			print Dumper($apus);
                	my $log = $apus->do_apu();
            }

        }
        $pop->Delete($i);
    }

   # system("rm -f /tmp/attached_prices/*");

    $pop->Close();

	$this->log("\n tyt bylo ".$pop->Count()." lustiv \n");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
