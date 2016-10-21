package Util;

use warnings;
use strict;

use Carp qw(carp croak);

use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use List::Util 'min';
use Time::HiRes ();
use LWP::UserAgent;
use HTTP::Request;

use Data::Dumper ();

our @EXPORT_OK
    = ( qw(check_sdomain_name sd_name alias lwp_get_url json_decode json_encode dumper class_to_file class_to_path decamelize camelize tablify date date_log) );

### get params like this $_[0], $_[1];

sub date() {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
        = localtime();
    return
          sprintf( "%02d", $mday ) . '.'
        . sprintf( "%02d", $mon ) . '.'
        . ( $year + 1900 );
}

sub date_log() {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
        = localtime();
    return
          sprintf( "%02d", $mday ) . '-'
        . sprintf( "%02d", $mon ) . '-'
        . ( $year + 1900 ) . ' '
        . $hour . ':'
        . $min . ':'
        . $sec;
}

sub clean_alias {
    my ($my, $t ) = @_;
    $t =~ s/™//g; #'
    $t =~ s/’//g; #'
    return $t;
}

sub sd_name() {
    my $self = shift;
    my $host = shift;
    my ($sd) = ( $host =~ /(\w+)\.reklamadel\.com/ );
    if   ($sd) { return $sd; }
    else       { return 0; }
}

sub check_subdomain_name() {
    my $subdomain_name = shift;
    if ( $subdomain_name =~ /^[a-zA-Z0-9]$/ ) { return $subdomain_name; }
    return 0;
}

sub file_2csv() {
    my $my   = shift;
    my $file = shift;
    my $ext  = &file_get_ext($file);
    my $func = $ext . '2csv';
    return 1;
}

sub _upload_get_name() {
    my $my = shift;
    my $f  = shift or return 0;
    my @ar = split /\/|\\/, $f;
    my $fn = pop @ar;
    $fn =~ s/[^\w\ \d\.\-]//g;
    return 0 unless ($fn);
    return $fn;
}

sub file_get_ext() {
    my ( $my, $f ) = @_;
    if ($f) {
        my ( undef, $ext ) = split /\./, $f;
        return $ext;
    }
    else {
        return 0;
    }
}

sub lwp_get_url {
    my $ua = LWP::UserAgent->new();
    $ua->agent(
        'Mozilla/5.0 (Windows NT 6.1; WOW64)
          AppleWebKit/537.36 (KHTML, like Gecko)
          Chrome/35.0.1916.153 Safari/537.36'
    );
    my $r = $ua->get(shift);
    return $r->content();
}
sub json_decode { use JSON; return shift; }    #return decode_json(shift);
sub json_encode { use JSON; return JSON->new->utf8->encode(shift); }

sub camelize {
    my $str = shift;
    return $str if $str =~ /^[A-Z]/;
    return join '::', map {
        join '', map { ucfirst lc } split '_', $_
    } split '-', $str;
}

sub class_to_file {
    my $class = shift;
    $class =~ s/::|'//g;
    $class =~ s/([A-Z])([A-Z]*)/$1.lc($2)/ge;
    return decamelize($class);
}

sub class_to_path {
    return join '.', join( '/', split /::|'/, shift ), 'pm'

}

sub decamelize {
    my $str = shift;
    return $str if $str !~ /^[A-Z]/;

    # Module parts
    my @parts;
    for my $part ( split '::', $str ) {

        # snake_case words
        my @words;
        push @words, lc $1 while $part =~ s/([A-Z]{1}[^A-Z]*)//;
        push @parts, join '_', @words;
    }
    return join '-', @parts;
}

sub dumper {
    Data::Dumper->new( [@_] )->Indent(1)->Sortkeys(1)->Terse(1)->Dump;
}

sub tablify {
    my $rows = shift;
    my @spec;
    for my $row (@$rows) {
        for my $i ( 0 .. $#$row ) {
            $row->[$i] =~ s/[\r\n]//g;
            my $len = length $row->[$i];
            $spec[$i] = $len if $len > ( $spec[$i] // 0 );
        }
    }
    my $format = join '  ', map( {"\%-${_}s"} @spec[ 0 .. $#spec - 1 ] ),
        '%s';
    return join '', map { sprintf "$format\n", @$_ } @$rows;
}

1;
