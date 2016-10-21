package Core::SMS;
use strict; use warnings; 

use Cfg; 

sub send_sms_to_phone(){ 
    my $this  		= shift;

    my $mess  		= shift or die('no mess spec');
    my $phone		= shift or die('no phone spec'); 

    my $SMS_login 	= $cfg->{SMS}->{login};
    my $SMS_pass  	= $cfg->{SMS}->{pass};
    my $SMS_url	  	= $cfg->{SMS}->{url};

	my $t = '<?xml version="1.0" encoding="utf-8"?><packet version="1.0"><auth login="'.$SMS_login.'" password="'.$SMS_pass.'"/><command name="sendmessage"><message id="111" type="sms"><data charset="cyr">'.$mess.'</data><recipients><recipient id="001" address="'.$phone.'">'.$mess.'</recipient></recipients></message></command></packet>';
	use LWP::UserAgent; use HTTP::Request;  my $q = HTTP::Request->new(POST => $SMS_url);   $q->content_type('application/xhtml+xml');  $q->content($t);  my $u = LWP::UserAgent->new();   my $rs = $u->request($q);  return $rs;
}

1;
