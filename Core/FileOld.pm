package Core::FileOld;

use Data::Dumper;
use Core;
use Core::DB;
use Cfg;
use Apache2::Upload;
use Apache2::Request;
use Spreadsheet::ParseExcel;

use Encode qw(encode decode is_utf8);

use strict;
use locale; 


sub new() { 
    my ($class) = shift; 
    my ($self)  = { 'xfile' => shift }; 
    bless ($self, $class); 
    return $self; 
}

sub upload_file(){
	my $self = shift;
	my $r = shift;
	my $apr = Apache2::Request->new($r);
    my $upl = $apr->upload('file') or return undef;
    $self->{'xfile'} = $upl->tempname;
	return $self;
}

sub replace() { 
    my $my = shift; 
    open(F, "> ".shift);  print(F "".shift); close(F); 
    return 1;   
}

sub parce() {
        my $self = shift;
        my $path = $cfg->{'PATH'}->{'root'}.'/tmp/xls';

        my $dir_exist = opendir(DIR,$path) or `mkdir -p $path`; closedir(DIR);

	    my $parser   = Spreadsheet::ParseExcel->new();

        my $workbook = $parser->parse($self->{'xfile'});
        
        if ( !defined $workbook ) { die $parser->error(), ".\n"; } 
        my @res;

        for my $worksheet ( $workbook->worksheets() ) {
            
            my ( $row_min, $row_max ) = $worksheet->row_range();
            my ( $col_min, $col_max ) = $worksheet->col_range();

            for my $row ( $row_min .. $row_max ) {
            
                my $rw;
                for my $col ( @{$self->{'cols'}} ) {
                    my $cell = $worksheet->get_cell( $row, $col ); 
                    next unless $cell; 

#                   $rw->{$col} = $cell->Value();

                    $rw->{$col} = encode('utf8',$cell->Value());
                }

                push @res,$rw;
            }
        }
        return \@res;
}

1;
