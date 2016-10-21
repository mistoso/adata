package Crond::CheckMailForAddPage;
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
	use Model::APRPages;
    use Core::APU;

    my $path = '/tmp/attached_prices/';
    my @apus;

    my $i;
	my $page;

    my $pop = new Mail::POP3Client( USER => 'vanyabrovaru@gmail.com',PASSWORD => 'i092708i', HOST => 'pop.gmail.com',USESSL   => true );
    $pop->Connect() >= 0 || die $pop->Message();

	for ($i = 1; $i <= $pop->Count(); $i++) {
        	my ($from,$subject,$id);
		#print ".";
		my $msg = Mail::MboxParser::Mail->new( [ $pop->Head($i) ],[ $pop->Body($i) ] );
		$from = $msg->from->{email};
		if ($from =~ /^<(.+)>$/) {$from = $1;}
		    my $subj = $msg->header->{subject};
		    #if ($subj =~ /^(=\?)(.+)(\?\ub\?)(.+)(\?=)$/){
		    if ($subj =~ /^add (\d+)$/i){
			$id = $1;
			$subject = $subj;
			$mail->{idCategory} = $id;
			$mail->{name} = `date`;
			$mail->{alias} = `date`;
			$mail->{page_text} = $msg->body($msg->find_body)->as_string();
			my $s = decode_base64($mail->{page_text});
        		$mail->{page_text} = $s;
			print Dumper($msg->body());
			print Dumper($msg->body($msg->find_body));
			print Dumper($msg->body($msg->find_body)->as_string());
			print Dumper(decode_base64($msg->body($msg->find_body)->as_string()));
			$mail->{page_text} = Encode::from_to(decode_base64($msg->body($msg->find_body)->as_string()), "utf8", "cp1250");
			print $mail->{page_text};
			my $apr_page = Model::APRPages->new($mail);
			$apr_page->save();	
					 
		}else{
			$subject = $subj
		}
#		$pop->Delete($i);
	}
	$pop->Close();
	$this->log("\n tyt bylo ".$pop->Count()." lustiv \n");

#--------------------------------------------------------------------
# Your code end
#--------------------------------------------------------------------
	return $this->{log};
}

1;
