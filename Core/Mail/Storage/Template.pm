package Core::Mail::Storage::Template;

use Core::Mail::Config qw/ template_path /;

BEGIN {
    use Exporter();

    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION     = 1.00;
    @ISA = qw();
    @EXPORT_OK = qw();
}

sub get_headers {
    my $name = shift;
    my $path = template_path();

    my $message = '';
    open (MAIL, $path.'/'.$name.'.hds') or return $message; 
    while (<MAIL>) {
        $message .= $_;
    }
    close MAIL;

    return $message;
}

sub get_html {
    my $name = shift;
    my $path = template_path();

    my $message = '';
    open (MAIL, $path.'/'.$name.'.htm') or return $message; 
    while (<MAIL>) {
        $message .= $_;
    }
    close MAIL;

    return $message;
}

sub get_txt {
    my $name = shift;
    my $path = template_path();

    my $message = '';
    open (MAIL, $path.'/'.$name.'.txt') or return $message; 
    while (<MAIL>) {
        $message .= $_;
    }
    close MAIL;

    return $message;
}

1;
