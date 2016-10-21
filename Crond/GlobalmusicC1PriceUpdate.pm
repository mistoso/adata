package Crond::CheckMailForGalaPriceUpdate;
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
    my $path = '/tmp/attached_prices/';
    my @apus;
    my $i;
	$this->log('start:'.time().'\n');
    my $stha = $db->prepare('SELECT id,idSaler,sender,subject FROM salerprices_auto_update WHERE active = 1');
    $stha->execute();
    while (my $apu = $stha->fetchrow_hashref){
        push @rules,$apu;
    }

    my $pop = new Mail::POP3Client( USER => 'galam.price@gmail.com',PASSWORD => 'galam2price', HOST => 'pop.gmail.com',USESSL   => true, );
	print $pop->Connect();
    $pop->Connect() >= 0 || die $pop->Message();
 
   for ($i = 1; $i <= $pop->Count(); $i++) {
        my ($from,$subject,$attach,$filename);
	

        my $msg = Mail::MboxParser::Mail->new( [ $pop->Head($i) ],[ $pop->Body($i) ] );
        $from = $msg->from->{email};
        if ($from =~ /^<(.+)>$/) {$from = $1;}
    
	for my $field ( split /\n/, $msg->get_field('received') ) {
        	print 'field>'.Dumper($field);# do something with $field
    	}

        my $subj = $msg->header->{subject};
        if ($subj =~ /^(=\?)(.+)(\?\ub\?)(.+)(\?=)$/){
            my $s = decode_base64($4);
            $subject = decode($2,$s);
        }else{
            $subject = $subj
        }
        
	my $mapping = $msg->get_attachments;
	for my $filename (keys %$mapping) {
		if ($filename =~ /\.(xls|zip|xlsb|csv)$/){$attach = $filename;}
   	}


	foreach my $rule (@rules){
        
		print "$from = ".$rule->{'sender'}.",\n==<br>==\n $subject =".$rule->{'subject'}."\n<br>,".Dumper($attach)."\n";
            
		if ((($rule->{'sender'} eq $from) || ($rule->{'subject'} eq $subject)) && ($attach ne '')) {
                	
			my $store = $msg->store_all_attachments(path => $path,store_only => qr/\.(xls|zip|xlsb|csv)$/i) ;		
			print Dumper($store);
    
			my $apu = Core::APU->new($rule->{'id'},$attach);
                	$apu->prepare_to_apu();		
			print Dumper($apu);

	                $apu->{'create_new_gala'} = 1;
        	        $apu->{'update_name'} = 1;
		#	$apu->{'exit'} = 1;		
	
			$apu->do_apu();
                	$this->log($apu->{'log'});                	
			
			$this->log("rm -f ".$apu->{'attached_file'});
			system('rm -f '.$apu->{'attached_file'});
			system('rm -f '.$path.$apu->{'file'}.'.csv');
		}

	}
	
	#$pop->Delete($i);
    }

    $pop->Close();

	$this->log("\n tyt bylo ".$pop->Count()." lustiv \n");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
