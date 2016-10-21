package Core::Mail::Query;

use Core::Mail::Storage::Template;
use Core::Mail::Storage::Query;
use Core::Mail::Parse;
use Core::Mail::Make;
use Core::Mail::Send;

use Logger;

sub queued {
    my $name    = shift;
    my $th      = shift;
    my $headers = shift;

    my $msg_headers = Core::Mail::Storage::Template::get_headers($name);
    my $msg_html    = Core::Mail::Storage::Template::get_html($name);
    my $msg_txt     = Core::Mail::Storage::Template::get_txt($name);

    if ($msg_html eq '') {
        $log->fatal("Core::Mail::Query: Cant load '$name' template(s)"); 
        return 0;
    }

    $msg_headers = Core::Mail::Parse::do($msg_headers,$th) if $msg_headers;
    $msg_html = Core::Mail::Parse::do($msg_html,$th) if $msg_html;
    $msg_txt = Core::Mail::Parse::do($msg_txt,$th) if $msg_txt;

    unless (ref($headers) eq 'HASH') {
       $headers = Core::Mail::Parse::headers($msg_headers);
    }

    if ($headers->{To} eq '' or $headers->{Subject} eq '') {
        $log->fatal("Core::Mail::Query: Cant find 'To' or 'Subject'");
        return 0;
    }  

    my $email = Core::Mail::Make->new($headers);
    $email->add_html($msg_html);

    if ($msg_txt) {
        $email->add_text($msg_txt);
    }

    unless (Core::Mail::Storage::Query::save($email->as_string)) {
        $log->fatal("Core::Mail::Query: Cant save message to query");
        return 0;
    }
    return 1;
} 

sub send {

    my $limit = Core::Mail::Config::send_limit();
    foreach (@{Core::Mail::Storage::Query::list()}) {
        $limit --;

        my $error = Core::Mail::Send::send($_->{message});
        unless ($error) { 
            $_->delete();
        }
        else { 
            $_->{error} = $error;
            $_->save();
        }

        last unless $limit;
    }
}

1;
