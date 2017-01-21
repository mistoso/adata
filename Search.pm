package Search;
use strict;

use DBI;

use Clean;
use Cfg;

#use String::Clean::XSS;

sub new() { 
    my $class = shift; 
    bless {}, $class; 
}

sub spx() { 
    my $my = shift; 
    $my->{_spx} ||= DBI->connect( "dbi:mysql:database=;host=127.0.0.1;port=9306", "", "", { mysql_no_autocommit_cmd => 1 } ); 
}

sub search_front(){
    my ($my, $str) = @_;  
    
    return 0 unless $str;

    my $h = $my->spx->prepare('select *, WEIGHT() w FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(?) AND price > 0 ORDER BY w ASC LIMIT 640 OPTION max_matches=640, ranker=bm25'); $h->execute( $str ); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref() ) { 
        push @b, $rs; 
    } 

    return \@b;
}

sub search_front_group(){
    my ($my, $str, $grp) = @_;  
    
    return 0 unless $str or $grp;

    my $h = $my->spx->prepare('select  COUNT(*) cnt, * FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(?) AND price > 0 GROUP BY '.$grp.' ORDER BY cnt DESC LIMIT 640 OPTION max_matches=640, ranker=bm25'); $h->execute($str); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref ){
        push @b, $rs; 
    } 

    return \@b;
}

sub search_front_in(){
    my ($my, $str, $col, $val) = @_;  
    
    return 0 unless $str;
    return 0 unless $col;
    return 0 unless $val;
    
    my $h = $my->spx->prepare('select *, WEIGHT() w FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(\''.$str.'\') AND '.$col.' = '.$val.' AND price > 0 ORDER BY w ASC LIMIT 640 OPTION max_matches=640, ranker=bm25'); $h->execute(); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref ){
        push @b, $rs; 
    } 

    return \@b;
}

sub search(){
    my ($my, $str) = @_;  
    
    return 0 unless $str;

    my $h = $my->spx->prepare('select *, WEIGHT() w FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(?) ORDER BY w ASC LIMIT 640 OPTION max_matches=640, ranker=bm25'); $h->execute( $str ); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref() ) { 
        push @b, $rs; 
    } 

    return \@b;
}

sub search_group(){
    my ($my, $str, $grp) = @_;  
    
    return 0 unless $str or $grp;

    my $h = $my->spx->prepare('select  COUNT(*) cnt, * FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(?) GROUP BY '.$grp.' ORDER BY cnt DESC LIMIT 640 OPTION max_matches=640, ranker=bm25'); $h->execute($str); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref ){
        push @b, $rs; 
    } 

    return \@b;
}

sub search_in(){
    my ($my, $str, $col, $val) = @_;  
    
    return 0 unless $str;
    return 0 unless $col;
    return 0 unless $val;
    
    print 'select *, WEIGHT() w FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(\''.$str.'\') AND '.$col.' = '.$val.' ORDER BY w ASC LIMIT 640 OPTION max_matches=640, ranker=bm25';
    
    my $h = $my->spx->prepare('select *, WEIGHT() w FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(\''.$str.'\') AND '.$col.' = '.$val.' ORDER BY w ASC LIMIT 640 OPTION max_matches=640, ranker=bm25'); $h->execute(); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref ){
        push @b, $rs; 
    } 

    return \@b;
}

sub search_comp(){
    my ($my, $str) = @_;  
    
    return 0 unless $str;

    my $h = $my->spx->prepare('select *, WEIGHT() w FROM '.$cfg->{sphinx}->{test_index}.' where MATCH(?) ORDER BY w ASC LIMIT 10 OPTION max_matches=10, ranker=bm25'); 
    $h->execute( $str ); 

    my @b = ();
    while ( my $rs = $h->fetchrow_hashref() ) { 
        push @b, $rs; 
    } 

    return \@b;
}

1;
