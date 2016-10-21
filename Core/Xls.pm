package Core::Xls;

use Data::Dumper;
use Core;
use Core::DB;
use Cfg;
use Spreadsheet::ParseExcel;

use Apache2::Upload;
use Apache2::Request;
use Model::SaleMod;

use Encode qw(encode decode is_utf8);

use strict;
use locale; 

sub new(){
	my $class = shift;
	my $self = bless {}, $class;
	
	return $self;
}

sub get_xls(){
	my $self = shift;
	my $r = shift;
	my $apr = Apache2::Request->new($r);
	my $upl = $apr->upload('file') or return undef;
	$self->{'xfile'} = $upl->tempname;
	return $self;
}

sub parce(){
        my $self = shift;

        my $path = $cfg->{'PATH'}->{'root'}.'/tmp/xls';

        my $dir_exist = opendir(DIR,$path) or `mkdir -p $path`; closedir(DIR);

        my $oBook = Spreadsheet::ParseExcel::Workbook->Parse($self->{'xfile'});

        my($iR, $iC, $oWkS, $oWkC);

        my @res = ();

        foreach my $oWkS (@{$oBook->{Worksheet}}) {
                for(my $iR = $oWkS->{MinRow}; defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++) {
                        my $row;
                        foreach my $coll ( @{ $self->{'cols'} } ){
                                my $col = $coll;
                                $col--;
                                $row->{$coll} = encode('cp1251',$oWkS->{Cells}[$iR][$col]->Value) if $oWkS->{Cells}[$iR][$col];
                               
                        }
                        push @res,$row;
               }
                last;
        }
        return \@res;
}

1;
