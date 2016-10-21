package Tools;
use warnings;
use strict;

use Apache2::Request;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::URI;

BEGIN {
	use Exporter   ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);        
	$VERSION     = 1.00;
	@ISA = qw(Exporter);
	@EXPORT = qw(rparam uparam);
        @EXPORT_OK   = qw(get_form_data get_multipart_form_data get_request get_request_param rparam uparam aparam sdiv geoip ip);
}


sub rparam($) { return get_request_param(shift); }
sub uparam($) { return upload(shift);}
sub aparam($) { my @buf = param(shift); return \@buf;}
sub get_request();
sub get_request_param($);
sub get_request_params($);


sub sdiv($$);
sub get_http_file($$);
sub get_local_file($$);
sub get_form_data($);
sub get_multiple_param($$);

sub geoip($);

sub ip($);

sub geoip($){
  my $r  = shift or return;
  use Apache2::Connection;
  use Geo::IP;
  my $gi = Geo::IP->open('/usr/share/GeoIP/GeoIP.dat') or return;

  return $gi->country_code_by_addr($r->connection->client_ip());

#  return $gi->country_code_by_addr($r->connection->remote_ip());
}

sub ip($){
  my $r  = shift or return;
  use Apache2::Connection;
#conn_rec->client_ip

  return $r->connection->client_ip();

#  return $r->connection->remote_ip();
}


sub get_multiple_param($$){
    my $r = shift or return;
    my $param = shift or return;

    my $apr = Apache2::Request->new($r);
    my @buf = $apr->param($param);

    use Data::Dumper;
    warn "Have a mult param  for $param ".Dumper(\@buf);
    return \@buf;
}


sub get_request_param($){
	my $key = shift;
	my $r = get_request();

	my $item =  get_request_params($r);
	return $item->{$key};
}

sub get_request_params($){
	my $r = shift or return;
#	return &get_form_data($r);

	if (my $pargs = $r->pnotes('request-data')){
#	    warn "Request fetched from cache\n";
	    return $pargs;
	}
#	warn "Processing new request method = ".$r->method().' caller: '.caller;
	my $apr = Apache2::Request->new($r);
	my @keys = $apr->param;
	my %args;
	foreach my $key(@keys){
	    $args{$key} = $r->method eq 'POST' ? $apr->body($key) : $apr->param($key);
#	    warn "got param $key = $args{$key}\n";
#	    my @value = $apr->param($key);
#	    next unless scalar @value;
#	    if (@value > 1) {
#		$args{$key} = \@value;
#	    }else{
#		$args{$key} = $value[0];
#	    }
	}

#	$args{UPLOAD} = $apr->upload || undef;
#	use Data::Dumper;
#	warn Dumper(\%args);
#	my $bargs = &get_form_data($r);
#	warn Dumper($bargs);
	$r->pnotes('request-data',\%args);
	return \%args;
}

sub get_multipart_request_param_fhandle(){
    my $r = shift or return;
    my $key = shift || 'file';

    use Apache2::Upload;
    my $apr = Apache2::Request->new($r);
    my $upl = $apr->upload($key);
    
    return $upl->fh;
}

sub get_multipart_request_param_iohandle(){
    my $r = shift or return;
    my $key = shift || 'file';

    use Apache2::Upload;
    my $apr = Apache2::Request->new($r);
    my $upl = $apr->upload($key);
    
    return $upl->io;
}


sub get_multipart_request_param_fname(){
    my $r = shift or return;
    my $key = shift || 'file';

    use Apache2::Upload;
    my $apr = Apache2::Request->new($r);
    my $upl = $apr->upload($key) or return undef;
    
    return $upl->tempname;
}

sub get_request(){
    my $r = Apache2::RequestUtil->request();
    return $r->prev if $r->prev;
    return $r;
}

sub get_form_data($){
    my $r = shift;

    my $data = '';
    if ($r->method eq 'POST') {
        my $buf;
        while (my $read_len = $r->read($buf, 8192)) {
            if ($read_len == -1) {
                die "read() error";
            }
            $data .= $buf;
        }
    }
    else {
        $data = $r->args;
    }

    my %args = ();

    if (defined $data) {
        %args = map { unescape_url($_) }
                split /[=&;]/, $data;
    }

    return \%args;
}




sub get_local_file($$){
	my ($source,$target) = @_;

	open F, ">$target" or return 0;
	binmode F;
	my $buffer;
	print F $buffer while read ($source,$buffer,1024);
	close F;
	return 1;
}

sub get_http_file($$){

	my ($source,$target) = @_;
	use Net::HTTP;
	my ($host,$url) = ($source =~ /^http:\/\/([^\/]+)(\/.+)$/);
	my $s = Net::HTTP->new(Host => $host ) or return undef;
	open F,">$target" or return undef;
	binmode F;
	
	$s->write_request(GET => $url, 'User-Agent' => "Mozilla/5.0");
	my($code, $mess, undef) = $s->read_response_headers; 
	my $readed = 0;
	my ($count,$tick,$buffer);
	do{
		$readed = $s->read_entity_body($buffer, 1024);
		last unless defined $readed;
		$count += $readed;
		print F $buffer;
		
	}while ($readed);
	
	close F;	
	return $count;
}

sub sdiv($$){
	my ($x,$y)=@_;
	return 0 if $y == 0;
	my $div = sprintf('%u',$x/$y);
	return $x % $y ? $div+1 : $div;
}


sub http_encode($){
	my $q = shift;
	$q =~ s/ /%20/g;
	return $q;
}	

sub unescape_url(){
    my $url = shift;
    $url =~ s/\+/%20/g;
    Apache2::URI::unescape_url($url);
}

sub get_multipart_form_data(){
    use CGI qw/param/;
    param(shift);
}

1;
