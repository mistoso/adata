package Tplc;
use strict;

#use latest;
use Apache2::RequestUtil;
use HTML::CTPP2();

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT, @EXPORT_OK );
    @ISA       = qw(Exporter);
    @EXPORT    = qw(get_template_c);
    @EXPORT_OK = qw(get_template_c);
}

sub get_template_c(%);

sub get_template_c(%) {
    my $theme  = shift;
    my $r      = shift;
    my %arg    = @_;   
    my $t_pth  = '/var/www/adata/html/backoffice/templates/ctpp/';
    
    #my $t_pth  = $cfg->{'PATH'}->{'templates'}.'backoffice/templates/ctpp/';
    
    my $t      = new HTML::CTPP2(); 

    if(%arg{a}->{c}){
        my $bytec = $t->parse_template($t_pth.$theme.'.tmpl'); 
        $bytec->save($t_pth.'c/'.$theme.'.ct2');
    }

    my $byte = $t->load_bytecode($t_pth.'c/'.$theme.'.ct2'); $t->param({%arg}); 
    my $out =  $t->output($byte);

    $r->headers_out->set('Content-Length' => length($out));
    $r->print($out);

    undef $theme, %arg, $t_pth, $t, $byte, $out;

    return 1;
}

1;
