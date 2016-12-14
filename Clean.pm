package Clean;

#use strict;

use HTML::TagFilter;
use String::Replace ':all';

sub tag_parsers() {
    my ( $my, $t ) = @_;
    $t = Clean->sql($t);
    $t = Clean->more($t);
    return $t;
}

sub all() {
	my ( $my, $t ) = @_; 
    $t = Clean->html($t);
    $t = Clean->sql($t);
    $t = Clean->spaces($t);
	return $t;
}

sub all_all() {
    my ( $my, $t ) = @_; 
    $t = Clean->html($t);
    $t = Clean->sql($t);
    $t = Clean->more($t);
    $t = Clean->tag($t);
	return $t;
}

sub more() {
    my ($my, $t ) = @_;  
    $t = Clean->sql($t);
    $t = Clean->symbols($t);
    $t = Clean->spaces($t);
    return $t;
}

sub datatable(){ 
    my ( $my, $t ) = @_;
    $t = Clean->spaces($t);
    $t = Clean->symbols($t);
    $t =~ s/ {2,}/ /g;
    return $t;
}


sub sphinx {
    my ( $my, $t ) = @_;
    $t = Clean->all($t);
    return $t;
}

sub file_name(){ 
    my ( $my, $t ) = @_;
    $t = Clean->more($t);
    return $t;
}

sub white_space {
    my ($my, $t ) = @_;
    $t =~ s/^\s+//g;
	$t =~ s/\s+$//g;
    return $t;
}

sub sql {
    my ($my, $t ) = @_;
    $t =~ s/'//g; #'
    $t =~ s/\\//g;
    return $t;
}

# Characters that should be escaped in XML (keeped from Mojo by ivanb)
sub xml {
    my ( $my, $t ) = @_;
    return replace( $t, { '&'  => '&amp;', '<'  => '&lt;', '>'  => '&gt;', '"'  => '&quot;',  '\'' => '&#39;' } );
}

sub spaces {
    my ( $my, $t ) = @_;
    return replace( $t, { '\r'=>'','\t'=>'', '  '=>' '} );
}

sub symbols {
    my ( $my, $t ) = @_;
    return replace( $t, { '\('=>'', '\)'=>'', '\*'=>'', '\.'=>'', '}'=>'', '{'=>'', '-'=>'', '_'=>'', '+'=>'','!'=>'','script'=>'', '&nbsp;'=>' '} );
}

sub sname { 
    my ( $my, $t ) = @_; 
    return replace( $t, { 'www.'=> '','.kiev'=> '','.cn'=> '','.in'=> '','.ssh'=> '','.com'=> '','.net'=> '','.ua'=> '','.ru'=> '' }); 
}

sub a { 
    my ( $my, $t ) = @_; 
    return replace( $t, { '<a'=> '#a','< a'=> '#a','a >'=> 'a#' ,'a>'=> 'a#' }); 
}


sub html {
    my ( $my, $t ) = @_;
    my $c = HTML::TagFilter->new( deny => { } );
    return $c->filter($t);
}

sub sql {
    my ( $my, $t ) = @_;
	$t =~ s/'//g; #'
	$t =~ s/\\//g;
	return $t;
}

sub more {
    my ($my, $t) = @_; $t =~ s/[\t|\n|\r]/ /g; $t =~ s/> />/g; $t =~ s/ </</g; $t =~ s/^\s+//g; $t =~ s/\s+$//g; $t =~ s/[\(|\)|{|}|\.|&nbsp;|script|&|\*|\"]//g;
    $t =~ s/[  |    |    ]//g;
    return $t;
}

sub a {
    my ( $my, $t ) = @_;
    my $c = HTML::TagFilter->new( deny => {   'a'      => {'all'}  } );
    return $c->filter($t);
}

sub tag {
    my ($my, $t) = @_;
    unless ($my->{__tag_filter}) { 
        $my->{__tag_filter}  = HTML::TagFilter->new(
            allow=> {
                'b'      => {'all'}, 
                'br'     => {'all'}, 
                'ul'     => {'all'}, 
                'li'     => {'all'},
            }

        );
    }
    return $my->{__tag_filter}->filter($t);
}

##############################################################

1;


