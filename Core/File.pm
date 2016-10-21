package Core::File;
use warnings; use strict;

sub ext() { 
	my $my = shift; my @a  = split( '\.', shift ); return pop @a;
}

sub name() { 
	my ( $my, $name ) = @_; $name =~ s/[^\w\ \d\.\-|\-| {1,}|_{2,}]/_/g; my @a  = split( /\/|\\/, $name ); return pop @a; 
}

sub upload() { 
	my $my = shift; 
	my $rq = Apache2::Request->new( shift ); 
	my $up = $rq->upload("file"); 
	return $up->link( shift );
}

sub is() {
	my ($my, $file) = @_; return $file if (-w $file );
}

sub replace() { 
	my $my = shift; open(F, "> ".shift);  print(F "".shift); close(F); return 1;
}

sub insert() { 
	my $my = shift; open(F, ">> ".shift); print(F "".shift); close(F); return 1;
}

sub tail() { 
	my ( $my, $str ) = @_; my @b = `tail -n10000 /var/log/www/users.log |grep $str`; return \@b;
}

sub fdate(){
	my $self = shift; my $date = `date +%Y-%m-%d-%T`; $date =~ s/\n//; return $date; 
}

sub read() { 
	my $my = shift; open(F, " ".shift); my @b = <F>; close(F); return \@b;
}

sub logs() { 
	my $my = shift; open(F, ">> ".shift); print(F "".$my->fdate()." ".shift); close(F); return 1;   
}

sub tail_logs() { 
    my $my   = shift;
    my $html = '<table width="100%" style="font-family:Verdana,sans-serif;font-size:12px;color:#484848;">';
    $html .= "<tr bgcolor=#ECECE4><td><b>Date</b></td><td><b>User</b></td><td><b>Manage</b></td><td><b>Action</b></td><td><b>Key</b></td></tr>";
    my $host = shift;
    foreach ( @{$my->tail( $host )} ) { $html .= "<tr bgcolor=#ECECE4><td><i>$_</i></td></tr>"; }
    $html .= "</table>";
    $html =~ s/\t/<\/td><td>/g;
    $html =~ s#$host##g;
    return $html; 
}

sub read_csv2html() { 
    my $my   = shift;
    my $html = '<table>';
  # $_ =~ s/,/<\/td><td>/g; $_ =~ s/$/<\/i><\/td><\/tr>/g; $_ =~ s/\"//g; $_ =~ s/[^A-Za-z0-9\.,_\-\(\):\/;<>]/ /g;

    foreach ( @{$my->read(shift)} ) {
	  $html .= "<tr><td>$_</td></tr>"; 
    }
    $html .= "</table>";
    
    $html =~ s/,/<\/td><td>/g;
    
    return $html; 
}

sub unlink()   { 
	my $my   = shift; my $file = $my->is( shift );  `unlink $file` if defined $file;
}

sub wget() { my $my = shift; return `wget shift -O shift`; }

1;
