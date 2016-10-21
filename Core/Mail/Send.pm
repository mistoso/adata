package Core::Mail::Send;
use Core::Mail::Config;

sub send {
    my $message = shift;
    open (MAIL, "| /usr/sbin/sendmail -f'".Core::Mail::Config::from()."' -t |") or return "$!";
    print MAIL $message;
    return '';
}

1;
