package Tpl;

use warnings;
use strict;

BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT, @EXPORT_OK );
    @ISA       = qw(Exporter);
    @EXPORT    = qw(get_template);
    @EXPORT_OK = qw(get_template);
}

sub get_template(%);

sub get_template(%) {
    my $theme   = shift;
    my $output  = shift;
    my %arg     = @_;
    use Template;
    use Template::Stash;
    $arg{url} 	= $output->uri();
    use Tools;
    $arg{a}     = &Tools::get_request_params($output);
    $arg{geoip} = &Tools::geoip($output);
    $arg{theme} = 'arctic';     ## fast add. Needed refactoring. for backoffice
    use Core;
    $arg{lib}   = Core->new();
    $theme      =~ tr/\\/\//;
    $theme     .= '.html';

    use Cfg;

    my $tt_obj;

    $tt_obj = Template->new({ INCLUDE_PATH => $cfg->{'PATH'}->{'templates'} .  'jqw/'});
    
    my $output_html = '';

    $tt_obj->process( $theme, \%arg, \$output_html ) or do {
    
        my $err = $tt_obj->error();

        if($err =~ /^file error - (.+): not found$/mg){
            print "not found: ".$1;
        } else {
            print $err;
        }
        return 0;
    };

    #$output_html =~ s/^[ |\n|\t]+//mg;
    #$output_html =~ s/^[ |\n|\t]+$//mg;
    
    $output_html =~ s/ {2,}/ /mg;
    $output_html =~ s/\t/ /mg;
    $output_html =~ s/^[ |\n]+$//mg;
    $output_html =~ s/^[ |\n]+//mg;
    $output_html =~ s/ {2,}/ /mg;
    $output_html =~ s/ >/>/mg;
    $output_html =~ s/> />/mg;
    $output_html =~ s/: /:/mg;
    $output_html =~ s/{ /{/mg;
    $output_html =~ s/{\n/{/g;
    $output_html =~ s/ }/}/mg;

    use Apache2::RequestUtil;
    $output = Apache2::RequestUtil->request();
    eval { $output->puts($output_html) };
    if ($@) {

        use Logger;
        $log->fatal( "Catch: (" . $output->uri() . ")" . $@ );
        $output = Apache2::RequestUtil->request();
        eval { $output->puts($output_html) };
    }

    return 1;
}

$Template::Stash::SCALAR_OPS->{dropHTML} = sub {
    my $val = shift;
    $val =~ s/<.+?>//g;
    return $val;

};

    ## Above... was comented in TplShop.pm
    #use Logger;
    #$log->fatal("Catch: (".$output->uri().")".$@);
    ## Not comented in Tpl.pm

    #$output_html =~ s/[\[%|%\]]//mg;
    # use Error;
    # Error->clean();
    ## Above... was comented in TplShop.pm
    ##########tttttteeeessssstttt mmaaaayyybbbbeeee encoding
    #    use Apache2::RequestUtil;
    #    $output =  Apache2::RequestUtil->request();
    ######################################################
    ## Not comented in Tpl.pm

1;
