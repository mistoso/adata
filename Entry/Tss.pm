package Entry::Tss;

use modules 	   qw( warnings strict Cfg Config::IniFiles Util Data::Dumper Tools );
use Apache2::Const qw/ OK NOT_FOUND M_GET /;

our ( $r, $arg, $q, $d, $s, %pkg );

tie %pkg, 'Config::IniFiles', ( -file =>  $cfg->{pkg} );

sub handler() {
    $r 	 = shift; 
    $q 	 = $r->uri(); 
    $arg = &Tools::get_request_params($r);
    $r->content_type('text/html; charset=utf-8'); 

    my %c = ( 
	"\\/tss\\/list\\/([" . $cfg->{A} . "]+)\\.([json|html]+)" 	=> *tss_list{CODE},
	"\\/tss\\/list_csv\\/([" . $cfg->{A} . "]+)\\.([json|html]+)" 	=> *tss_list_csv{CODE} 
    );

    foreach my $e ( keys %c ) { if ((my @a=($q =~ /^$e$/)) && $r) { return &{$c{$e}}(@a); } }
    return NOT_FOUND;
}

sub tss_list(){
    my $name = shift;
    my $type = shift;
    my $cls  = %pkg->{$name}->{pkg};
    my $file = Util::class_to_path($cls);

    eval { require $file; } or do { return $@; };

    my $res = ModelList->new( $cls , 0, 100000); $res->load();

    return &_view( 'tss/list/'.$name, $res->list() )
        if $type eq 'html';

    return &_view( 'json', $res->list() )
        if $type eq 'json';
}

sub _view() {
    use Tpl qw/ get_template /;
    get_template( $_[0] => $r, itm => $_[1] );
    return OK;
}


### SOGOOD Tss.pm ###
#####################
#package Entry::Tss;

# use warnings;
# use strict;

# use Apache2::Const qw/ OK NOT_FOUND M_GET /;
# use Cfg;
# use Tools;
# use Config::IniFiles;

# our ( $r, $q, $arg, %pkg, %c );

# sub handler() {
#     $r    = shift; $q = $r->uri();
#     $arg  = &Tools::get_request_params($r);
#     %c    = ( "\\/tss\\/list\\/([".$cfg->{A}."]+)\\.([json|html]+)" => *tss_list{CODE}  );
#     foreach my $e ( keys %c ) {
#         if ((my @a=($q =~ /^$e$/)) && $r) {
#             return &{$c{$e}}(@a);
#         }
#     }
#     return NOT_FOUND;
# }

# sub tss_list(){
#     my ( $name, $type ) = @_;

#     my $cls  = %pkg->{$name}->{pkg};
#     use Util;
#     my $file = Util::class_to_path($cls);
#     eval { require $file; } or do { return $@; };
#     my $res = ModelList->new( $cls , 0, 100000);
#     $res->load();
#     return &_view( 'tss/list/'.$name, $res->list() ) if $type eq 'html';
#     return &_view( 'json', $res->list() )            if $type eq 'json';

# }

# sub _view() {
#     use Tpl qw/ get_template /;
#     $r->content_type('text/html');
#     get_template( $_[0] => $r, itm => $_[1] );
#     return OK;
# }

1;
