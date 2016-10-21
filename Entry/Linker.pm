package Entry::Linker;

use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;

use Apache2::SubRequest;
use Apache2::RequestRec;

use Logger;
use Core::DB;
use Tools;
use Core::Template qw/get_template/;
use Data::Dumper;
use Core::Session;
use Core::User;
use Cfg;                   
use Core::Error;
use Encode;
use Clean;
use Digest::MD5 qw(md5_hex);
our $r;
our $s;
our $user;
our $args;
my $ALIAS = "\\w \\d \\- \\+ \\( \\) \\_ \\#";
sub handler(){
    our $r = shift;
    my $req = $r->uri();
    $r->content_type('text/html');
    our $args = &Tools::get_request_params($r);
    our $params_string = '';
    map { $params_string .= $_."=".$args->{$_}."&" } keys %{$args};
    #--------------------------------------------------------------------------------------------
    $s = Core::Session->instance(1);
    our $user = Core::User->current();

    my %content = (
                "\\/2131d4055a03e1f873e3dd62372fe06b\\/gate\\.pl" => *linker_gate{CODE},
	);
    map { $args->{$_} = Clean->all($args->{$_}) } keys %{$args};
    foreach my $reg (keys %content){
        if (my @args = ($req =~ /^$reg$/)){
            return &{$content{$reg}}(@args);
            return $r if $r;
        }
    }
    return NOT_FOUND;
}

sub redirect($);
sub redirect($){
    my $href = shift;
    $r->method('GET');
    $r->method_number(M_GET);
    $r->internal_redirect($href);
}

sub linker_gate(){
    if( $args->{action} eq 'placeLink') {
		&linker_sub_placeLink();
    }elsif( $args->{action} eq 'placeTexts' ) {
		&linker_sub_placeTexts();
    }elsif( $args->{action} eq 'placeInternals' ) {
		&linker_sub_placeInternals();
    }elsif( $args->{action} eq 'clearDB' ) {
		&linker_sub_clearDB();
    }else{
		return NOT_FOUND;
    }
}

sub linker_sub_placeLink(){
    if($args->{uris} && $args->{'link'} && $args->{url_text}) {
		my @uris = split('{sslinker}', $args->{uris});
		foreach my $uri (@uris) {
	    		if($uri){
				my $ss_storage_filename = substr(md5_hex($uri), 0, 2);
				my $line = "domain:".$args->{domain}."\turl:".$uri."\tlink:".$args->{'link'}."\ttext:".$args->{url_text_before}." <a href=\"".$args->{'link'}."\" target=\"_blank\">".$args->{url_text}."</a> ".$args->{url_text_after}."\n";

				open FILE, ">>".$cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/links/".$ss_storage_filename.".db" or die $!;
				print FILE $line;
				close FILE;
	    		}
		}
		print '0:OK';
		return OK;
    } else {
		return NOT_FOUND;
    }
}

sub linker_sub_placeTexts(){
    my $domain = $args->{domain};
    my $data = $args->{data};
    if ($data) {
        my @data = split('{sslinker}', $data);
        foreach my $item (@data){
		my @parts = split("\t", $item);
            	my $uri = @parts[0];
		my $ss_storage_filename = substr(md5_hex($uri), 0, 2);
		open FILE, ">>".$cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/texts/".$ss_storage_filename.".db" or die $!;
            my $cnt = scalar(grep $_, @parts) - 1;
            for(my $i = 1; $i <= $cnt; $i++) {
                my @ww = split(":", @parts[$i]);
                my $weight = @ww[0];
                my $word   = @ww[1];
				my $line = "domain:$domain\turi:$uri\ttext:$word\tweight:$weight\n";
           	
                print FILE $line;
            }
            close FILE;
       	}
       		print '0:OK';
		return OK;
    } else {
		return NOT_FOUND;
    }
}

sub linker_sub_placeInternals(){
    my $domain = $args->{domain};
    my $data = $args->{data};
    if ($data) {
        my @data = split('{sslinker}', $data);
        foreach my $item (@data) {
            my @parts = split("\t", $item);
            my $uri = &str_replace('uri:', '', @parts[1]);
			my $ss_storage_filename = substr(md5_hex($uri), 0, 2);
			open FILE, ">>".$cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/internal/".$ss_storage_filename.".db" or die $!;

            print FILE "$item\n";
            close FILE;
        }
    	    print '0:OK';
	    return OK;
    } else {
		return NOT_FOUND;
    }
}

sub linker_sub_clearDB(){
    my $db_path = $args->{dbpath};

    if ($db_path eq 'texts' || $db_path eq 'internal' || $db_path eq 'links') {
	$db_path = $cfg->{'stt_catalog'}->{'OUTPUT_PATH'}."linker/".$db_path."/*";
	`rm -f $db_path`;
	print '0:OK';
	return OK;
    } else {
		return NOT_FOUND;
    }
}

sub str_replace {
	my $replace_this = shift;
	my $with_this  = shift; 
	my $string   = shift;
	my $length = length($string);
	my $target = length($replace_this);
	for(my $i=0; $i<$length - $target + 1; $i++) {
		if(substr($string,$i,$target) eq $replace_this) {
			$string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
			return $string; #Comment this if you what a global replace
		}
	}
	return $string;
}


1;
