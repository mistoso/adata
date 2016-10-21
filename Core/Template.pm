package Core::Template;

use strict;

use Core;

use Logger;
use Cfg;
use Tools;
use Core::User;
use Core::Session;

use Template;
use Template::Stash;

use Apache2::RequestUtil;
#use Core::Error;
use Core::Price;
use Core::Meta;

use Banner;


BEGIN {
    use Exporter();
    our ( @ISA, @EXPORT, @EXPORT_OK );
    @ISA       = qw(Exporter);
    @EXPORT    = qw(get_template);
    @EXPORT_OK = qw(get_template);
}

sub get_template(%);

sub get_template(%){
    my $theme   = shift;
     my $output = shift;
     my %arg    = @_;
    $arg{args}  = &Tools::get_request_params($output);

    $arg{banner}= Banner->new();

    $arg{lib}    = Core->new();
    $arg{user}   = Core::User->current();
    $arg{Meta}   = Core::Meta->instance();
    $arg{price}  = Core::Price->new();
    $arg{session}= Core::Session->instance();
    $arg{config} = $cfg->{'temp'};

    my $tt_obj = Template->new({
        TAG_STYLE => 'html',
        INCLUDE_PATH => $cfg->{'stt'}->{'OUTPUT_PATH'}.":".$cfg->{'PATH'}->{'templates'}
    }); 


    $theme =~ tr/\\/\//;
    $theme .= '.html';
    my $output_html = '';

    $tt_obj->process($theme, \%arg,\$output_html) or do { 
        print $tt_obj->error(); return 0; 
    };

   $arg{session}->deleteObj();

    my $output =  Apache2::RequestUtil->request();

    $output_html =~ s/\t/ /mg;
    $output_html =~ s/\n/ /mg;
    $output_html =~ s/ {2,}/ /mg;



    eval { 
        $output->puts( $output_html )
    };
   
    if ($@) {
        $log->fatal("Catch: (".$output->uri().")".$@);
        my $output = Apache2::RequestUtil->request();
        eval {$output->puts($output_html)};
    }
    return 1;
}



# sub get_template(%);

# sub get_template(%) {
#     my $theme  = shift;
#     my $output = shift;
#     my %arg    = @_;

#     use Template;
#     use Template::Stash;
#     use Cfg;
#     use Core;
#     use Sessions::Client;

#     $arg{lib} = Core->new();
#     $arg{cfg} = $cfg;
#     $arg{ses} = Sessions::Client->new($output);
#     $arg{url} = $output->uri();

#     $theme =~ tr/\\/\//;
#     $theme .= '.html';

#     my $tt_obj;

#     if ( $arg{shop} = Model::Shop->current() ) ## if subdomain
#     {
#         if ( $arg{url} =~ /\/admin\/|\/cl\//mg ) ## subdomain /admin/
#         {
#         $arg{theme}     = $arg{ses}->get( $arg{a}, 'theme' );    
#         $arg{language}  = $arg{ses}->get( $arg{a}, 'language' ); #fast add 
#         $tt_obj = Template->new( $cfg->{TT_CO} ); # CACHE_SIZE => 0 
#         }

#         else 
#         {
#             ## subdomain /
#             $tt_obj = Template->new(
#                 {   INCLUDE_PATH => $cfg->{TT_FO}->{INCLUDE_PATH} . $arg{shop}->tt->alias
#                 }
#             );
#         }
#     }

#     else 
#     {
#         $arg{theme}     = $arg{ses}->get( $arg{a}, 'theme' );    
#         $arg{language}  = $arg{ses}->get( $arg{a}, 'language' ); #fast add 
#         $tt_obj = Template->new( $cfg->{TT_CO} );
#     }

#     my $output_html = '';

#     $tt_obj->process( $theme, \%arg, \$output_html ) or do {
#         my $er = $tt_obj->error();
#         if ( $er =~ /^file error - (.+): not found$/mg ) {
#             print "not found: " . $1;
#         } else { 
#             print $er; 
#         }
#         return 0;
#     };

#     $output_html =~ s/^[ |\n|\t]+$//mg;
#     $output_html =~ s/^[ |\n|\t]+//mg;
#     $output_html =~ s/ {2,}/ /mg;

#     use Apache2::RequestUtil;
#     $output = Apache2::RequestUtil->request();
#     eval { $output->puts($output_html); };

# ##################################################################
#     if ($@) {
# ##### was commented 29-02-16. Warning! Looking for bad charsets ?????
#         #       use Logger;
#         #   $log->fatal( "Catch: (" . $output->uri() . ")" . $@ );

#         $output = Apache2::RequestUtil->request();
#         eval { $output->puts($output_html) };
#     }
# #####################################################################
#     return 1;
# }

$Template::Stash::SCALAR_OPS->{excludeHref} = sub {
    my $val = shift;

    $val =~ s/\r\n//g;
    while (my ($cnt) = ($val =~ /<a [^>]*>([^<]+)<\/a>/)){
    $val =~ s/<a [^>]*>[^<]+<\/a>/$cnt/;
    }

    $val;
    
};

$Template::Stash::SCALAR_OPS->{mimeBase64} = sub {
    my $r =encode_base64(shift);
    chomp($r);
    $r;
};


$Template::Stash::SCALAR_OPS->{to_substr} = sub {
    my $val = shift;
    $val =~ s/для детей//g;
    return $val;
};


$Template::Stash::SCALAR_OPS->{xmlSafe} = sub {
    my $val = shift;

    $val =~ s/&/&amp;/g;
    $val =~ s/"/&quot;/g; #"
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/'/&apos;/g;
    return $val;

};


$Template::Stash::SCALAR_OPS->{forSearch} = sub {
    my $val = shift;
    $val =~ s/[,|\n|\t|\+|\-|\)|\(|_|  ]+/ /g;
    $val = lc($val);
    $val =~ s/^ //g;
    $val =~ s/ $//g;
    return $val;
};

$Template::Stash::SCALAR_OPS->{isdef} = sub{defined(shift) };

$Template::Stash::SCALAR_OPS->{dateParse} = sub{
    my ($year,$mon,$day) = split(/-/,shift);
    return undef unless $year and $mon and $day;
    my $section = shift || 'day';

    return $year if $section eq 'year';
    return $mon if $section eq 'mon';
    return $day if $section eq 'day';
    return undef;
};
$Template::Stash::SCALAR_OPS->{round} = sub{sprintf('%.0f',shift)};

$Template::Stash::SCALAR_OPS->{smartdiv} = sub{
    my $value = shift;
    my $div = shift;
    return int($value/$div) + ($value % $div ? 1 : 0);
};

$Template::Stash::SCALAR_OPS->{cmodel} = sub {
    my $value = shift;
    my $class = shift;
    my $column = shift || 'id';
    my $unit = shift || $class;
    eval "use $unit;";
    my $model = $class->load($value,$column);

};

$Template::Stash::SCALAR_OPS->{fmtTime} = sub {
    my $val = shift;
    $val =~ s/:\d\d$//;
    return $val;
};

$Template::Stash::SCALAR_OPS->{uriEscape} = sub {
    use URI::Escape;
    uri_escape(shift);
};

$Template::Stash::SCALAR_OPS->{frmTime} = sub {
    my ($val,$fmt) = @_;
    $fmt = '%F' unless $fmt;
    my ($y,$m,$d,$h,$mm,$ss) = ($val =~ /(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/);
    
    use POSIX qw/strftime/;
    return strftime($fmt,$ss-1,$mm-1,$h-1,$d-1,$m-1,$y-1);
    
};

$Template::Stash::SCALAR_OPS->{dropP} = sub {
    my $val = shift;
    $val =~ s/<p>//g;
    $val =~ s/<\/p>//g;
    return $val;

};


1;
