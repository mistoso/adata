package Crond::Import1C;

use latest;

use Base::Translate;
use Clean;

use Model::SaleMod;

use Core::DB;
use Cfg;

use Data::Types	qw( :all );
use Data::Dumper;

use Time::HiRes	qw/ gettimeofday tv_interval/;

sub new() {
	my $class = shift;

	my $my  = {
		lib_path => shift,
		log 	 => '',
		ch_head  => '',
		ch_row   => '',
		ch_col   => '',
		ch       => '',
		l        => 0
	};

	return bless $my, $class;
}


sub execute {
	my $my = shift;
	use lib "$my->{lib_path}";
	## data cols
	my @c  = qw(undef id name idCategory idBrand Description DescriptionFull price discount coment photo1 photo2 photo3 photo4 photo5);
	$my->{ch_head} = \@c;

	foreach my $r ( @{ $my->_parse_file() } ) {
		print $my->{l}.",";
		$my->{l}++;
		my $m = $my->_check_salemod( $r ) or next;
		for(1..$#c) {
			$my->_html_td( $r->{$_} );
			#print $c[$_].":".$m->{$c[$_]}."\n";
			if( $my->_is_change( $m->{$c[$_]}, $r->{$_} ) ) {
				if($c[$_] eq 'price') {
					$my->_set_price_history( $m->{id}, $m->{$c[$_]}, $r->{$_} );
				}
				if ( $_ > 9 and $_ < 15 ) {
					$m->add_remote_img_check_src( $r->{$_} );
					next;
				}
				$my->_html_ch( $c[$_], $m->{$c[$_]}, $r->{$_} );
				$m->{$c[$_]} = $r->{$_};
			}
		}

		$my->_html_td_full( $my->{l}.'. '.$my->{ch} );
		$my->_html_tr;
		$m->save() if $my->{ch} ne '';
		( $my->{ch}, $my->{ch_col} ) = '';
	}
	say $my->_html();
	$my->log( "Parsed ".$my->{l} );
	$my->_fix_public();
	return $my->{log};
}

sub _is_change() {
	my ($my, $l, $r) = @_;

	return 0 if $r eq 'undef' or $r eq '';

	if( is_decimal($l) and is_decimal($r) ) { return 0 if to_int($l) == to_int($r); }
	if( is_int($l) 	   and is_int($r)     ) { return 0 if $l == $r; }
	if( is_string($l)  and is_string($r)  ) { return 0 if $l eq $r; }

	return 1;
}

sub _set_price_history() {
	my $my = shift;
	my $h = $db->prepare("insert into price_history set mod_id = ?, price_old = ?, price_new = ?;");
	$h->execute( shift, shift, shift );
	return 1;
}

sub _check_salemod() {
	my $my = shift;
	my $r  = shift;

	return 0 if !is_count($r->{'1'}) or $r->{'1'} eq '' or $r->{'2'} eq '';

	my $m = Model::SaleMod->load( $r->{'1'} );
	return $m if $m->{id};

	eval {
	  my $h = $db->prepare("insert into salemods set id = ?, name = ?, alias = ?");
	  $h->execute( $r->{'1'}, $r->{'2'}, Base::Translate->translate( $r->{'2'} ) );
	};

	if($@){

	  print "<br>".$@."<br>".Dumper($r)."<br>";

	  my $h = $db->prepare("update salemods set id = ? where alias = ?");
	  $h->execute( $r->{'1'}, Base::Translate->translate( $r->{'2'} ) );

	  $m = Model::SaleMod->load( $r->{'1'} );

	}

	return $m if $m->{id};
}


sub _fix_public() {
	my $my = shift;

	my $h = $db->prepare("update salemods set isPublic = 0 where price = 0 and isPublic = 1"); $h->execute();
	my $h = $db->prepare("update salemods set isPublic = 1 where price > 0 and isPublic = 0"); $h->execute();

	return 1;
}

sub _parse_file() {
	my $my = shift;
	use Core::FileOld;
	#use Core::File;
	my $n = '/tmp/'.gettimeofday().'.db.xls';
	`rm -f /tmp/*.db.xls`;
	eval  {
	  $my->log(`wget 91.203.24.62/db/db.xls -O $n`);
#	  $my->log(`wget 176.104.1.249/db/db.xls -O $n`);
	};

	if($@){
	  print $my->{log};
	  die($my->{log});
	}

	my $f = Core::FileOld->new( $n );
	$f->{'cols'}  = [0..14];


	return $f->parce() || 0;

}

sub _html(){
	my $my = shift;
	my $h = '';
	$h .= '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">';
	$h .= '<html>';
	$h .= '<head>';
	$h .= '<META http-equiv=Content-Type content="text/html; charset=utf8">';
	$h .= '<link href="/admin/css/adminstyle.css" rel="stylesheet" type="text/css">';
	$h .= '</head>';
	$h .= '<body>';
	$h .= '<table width="100%" border="0" cellpadding="3" cellspacing="1" bgcolor="#cccccc" class="main-txt-s">';
	$h .= '<tr bgcolor="#ffecd9"><thead><tr>';
	for( @{ $my->{ch_head} } ) {
		next if $_ eq 'undef';
		$h .= '<TH>'.$_.'</TH>';
	}
	$h .= '<TH>diff</TH></tr></thead>';
	$h .= '<tbody>'.$my->{ch_row}.'</tbody>';
	$h .= '</table>';
	$h .= '</body></html>';
	$my->{ch_head} = '';
	$my->{ch_row}  = '';
	$my->{ch_col}  = '';
	return $h;
}

sub _html_td_full()	{ my $my = shift; $my->{ch_col} .= '<td>'.shift.'</td>'; }
sub _html_td()		{ my $my = shift; $my->{ch_col} .= '<td>'.substr(Clean->tag(shift),0,20).'</td>';}
sub _html_tr()		{ my $my = shift; $my->{ch_row} .= '<tr bgcolor="#FFFFFF">'.$my->{ch_col}.'</tr>'; }
sub _html_ch()		{ my $my = shift; $my->{ch} 	.= '<br><b>'.shift.':</b><br><em>'.shift.'='.shift.'</em><br>';}

sub log() { my $my = shift; $my->{log} .= shift."<br>"; }

1;

