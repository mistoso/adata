package Entry::Search; 
use Apache2::Const qw/OK M_GET NOT_FOUND/; 
our ( $r, $s, $a, $q ); 
sub handler(){
    $r = shift; 
    $q = $r->uri(); 
    $r->content_type('text/html'); 

    use Core::Session;
    $s = Core::Session->instance(1); 

    use Tools; 
    $a = &Tools::get_request_params($r);

    my $ALIAS = " \\_ \\w \\d \\- \\+ \\( \\) \\: \\, \\. ";

    my %c = ( "\\/search\\/" => *search_index{CODE} );
    
    foreach my $e ( keys %c ){ 
  	  if ( my @a = ( $q =~ /^$e$/ ) ) { 
  		return &{ $c { $e } } ( @a ); 
  		return $r if $r;
  	  } 
  	} 

    return NOT_FOUND;
}

sub search_index() {  
        
    return NOT_FOUND unless exists $a->{q};
    
    use Search;
    my $res = '';
    
    $res    = Search->new->search_front_in ( $a->{q}, 'category_id', $a->{category_id} ) if exists $a->{category_id};
    $res    = Search->new->search_front_in ( $a->{q}, 'brand_id',    $a->{brand_id}    ) if exists $a->{brand_id};

    if( !$a->{brand_id} and !$a->{category_id} ){
        $res    = Search->new->search_front    ( $a->{q} );
    }
    use Core::Template qw/get_template/;

    get_template(
        'frontoffice/templates/search_simple'   => $r,
        'rows_category'                         => Search->new->search_front_group( $a->{q}, 'category_id' ),
        'rows_brand'                            => Search->new->search_front_group( $a->{q}, 'brand_id'    ),
        'rows'                                  => $res,
    ); 
    return OK;
}

sub redirect($) { 
    my $href = shift; 
    $s->save(); 
    $r->method('GET'); 
    $r->method_number(Apache2::Const::M_GET); 
    $r->internal_redirect_handler($href); 
    exit;
}

1;
