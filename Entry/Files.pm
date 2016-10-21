package Entry::Files; 
use warnings; use strict;

use Apache2::Const qw/OK M_GET NOT_FOUND/;
use Core::TemplateFile; 
use Cfg; 
use Tools; 
use Core::FileOld; 
use Clean; 
use Data::Table; 
use Base::Translate;

our ( $r, $a, $q, $s, $ALIAS ); 

sub handler(){
    $r = shift; $q = $r->uri(); 

    $r->content_type('text/html'); 
    
    $a = &Tools::get_request_params($r);

    $ALIAS = $cfg->{temp}{ALIAS};

    my %c  = ( 
        "\\/files\\/"               => *files_list{CODE},        
        "\\/files\\/upload\\/"      => *files_upload{CODE},
        "\\/files\\/unlink\\/"      => *files_unlink{CODE},
        "\\/files\\/2csv\\/"        => *files_2csv{CODE},
        "\\/files\\/csv2html\\/"    => *files_csv2html{CODE}
    );  
    
    foreach my $e (keys %c) {

        if (my @a=($q =~ /^$e$/)){ 
            return &{$c{$e}} (@a); 
            return $r if $r;  
        } 
    
    } 

    return NOT_FOUND;
}

sub files_upload() {
    Core::File->upload( $r, $cfg->{price}{$a->{ext}}.$a->{file} ); 
    &files_list();
}

sub files_2csv() {
    my $csv  = `$a->{ext}2csv $cfg->{price}{$a->{ext}}$a->{file}`;

    my $file = $cfg->{price}{csv}.Base::Translate->translate( $a->{file} ).'.csv';

    Core::File->replace( $file, Clean->datatable( $csv ) );

    get_template ( 
        'backoffice/templates/files/dir' => $r, 
        'itm' => Core::File->read_csv2html( $file ) 
    ); 
    return OK; 

}

sub files_csv2html() {       
    get_template ( 
        'backoffice/templates/files/dir' => $r, 
        'itm' => Core::File->read_csv2html($cfg->{price}{csv}.$a->{file})  
    ); 
    return OK; 
}

sub files_unlink() {
    Core::File->unlink( $cfg->{price}{$a->{ext}}.$a->{file} ); 
    &files_list();
}

sub files_list() {  
    get_template ( 'backoffice/templates/files/dir' => $r ); 
    return OK; 
}

sub redirect($) { 
    my $href = shift; 
    $s->save(); 
    $r->method('GET'); 
    $r->method_number( M_GET ); 
    $r->internal_redirect_handler($href);  
    exit;  
}

1;