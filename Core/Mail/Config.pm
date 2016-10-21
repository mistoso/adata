package Core::Mail::Config;
use Cfg;

BEGIN {
    use Exporter();

    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION     = 1.00;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( user pass from host hello template_path public_domain tmp_dir bcc);
}

sub user {
    return 0;
}

sub pass {
    return 0;
}

sub from {
    return $cfg->{mail}->{from};
}

sub host {
    return 0;
}

sub hello {
    return 0;
}
    
sub root_path {
    return $cfg->{PATH}->{root};
}

sub template_path {
    return $cfg->{mail}->{templates};
}

sub public_domain {
    return $cfg->{mail}->{public_domain};
}

sub tmp_dir {
    return $cfg->{PATH}->{tmp};
}

sub bcc {
    return $cfg->{mail}->{bcc};
}

sub send_limit {
    return $cfg->{mail}->{send_limit};
}

1;
