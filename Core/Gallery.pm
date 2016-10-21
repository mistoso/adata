package Core::Gallery;
#use warnings;
#use strict;
use Image::Magick;

use DB;

use Cfg;
use Logger;

our $gpath = $cfg->{'PATH'}->{'gallery'};

sub new(){ my ( $class, $name ) = @_; return undef unless $name; my $self = { name => $name, }; bless $self,$class; }

sub missing(){ my $self = shift; }

sub addRemote {
	my ( $self, $file, $impid ) = @_;

	my ( $name, $format ) = ( $file  =~ /\/(\w+)\.(\w+)$/ );

        my $possible = 'abcdefghijkmnpqrstuvwxyz1234567890ABCDEFGHJKLMNPQRSTUVWXYZ';

        my $filename = $cfg->{PATH}->{tmp}.'';

        while ( length( $filename ) < 64 ) { $filename .= substr( $possible, ( int( rand( length( $possible ) ) ) ), 1); }

	$filename .= '.img.'.$format;

	`wget '$file' -O '$filename' &> /dev/null`;

	###############################################
	my $id = $self->add( $filename, $impid );

    ########## commented by ivanb 25.05.2013 - unlink $filename;

    ###############################################

    return $id;
}

sub add(){
    my ($self,$fh,$impid) = @_;

    my $img = Image::Magick->new();
    open FIMG ,$fh or do { warn "Can`t open file $fh:$!"; return 0; }; 
    our $gpath = $cfg->{'PATH'}->{'gallery'};
    $img->Read(file => \*FIMG);
    close FIMG;

    return undef unless $img->Get('width');

    my $model = Core::Gallery::Image->new( {
		    name => $self->{name},
		    width => $img->Get('width'),
		    height => $img->Get('height'),
		    gOrder => $self->count() + 1,
		} );

    $model->save();


    my $id = $model->{id};

    `mkdir -m777 -p $gpath/$self->{name}/` unless(-d "$gpath/$self->{name}/");
    `touch $gpath/$self->{name}/index.htm` unless -e "$gpath/$self->{name}/index.htm";
    `touch $gpath/$self->{name}/../index.htm` unless -e "$gpath/$self->{name}/../index.htm";

    $img->Write("$gpath/$self->{name}/image_$id.png");

    return $id;
}

sub images(){
    my $self = shift;

    unless ($self->{_images}){
    my $sth = $db->prepare('SELECT id FROM gallery WHERE name = ? ORDER BY gOrder');
    $sth->execute($self->{name});
    while (my ($id) = $sth->fetchrow_array){
        push @{$self->{_images}}, Core::Gallery::Image->load($id);
    }
    }
    return $self->{_images};
}

sub count(){
    my $self = shift;
    my $sth = $db->prepare('SELECT COUNT(id) FROM gallery WHERE name = ? ');
    $sth->execute($self->{name});
    my ($c) = $sth->fetchrow_array || (0);
    return $c;
}

sub top(){
    my $self = shift;

    unless ($self->{_top}){
    my $sth = $db->prepare('SELECT id FROM gallery WHERE name = ?   ORDER BY gOrder LIMIT 1');
    $sth->execute($self->{name});
    my ($id) = $sth->fetchrow_array;
    $self->{_top} = Core::Gallery::Image->load($id) || Core::Gallery::Image::Default->new();
    }

    return $self->{_top};
}

package Core::Gallery::Image;
use Model;
use Image::Magick;
use DB;
use Cfg;
use Logger;
#use warnings;
#use strict;

our $MSG_CODES = {
    ERR_CREATE_FILE => '',
};

our $gpath = $cfg->{'PATH'}->{'gallery'};
our @ISA = qw/Model/;

sub db_table(){'gallery'};
sub db_columns() {qw/id name height width gOrder/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub changeorder(){
    my ($self,$position) = @_;

    my $sth = $db->prepare("SELECT id FROM gallery WHERE 
                (gOrder - ($position),name) IN 
                (SELECT c.gOrder,c.name FROM gallery c WHERE c.id = ?)  LIMIT 1");

    $sth->execute($self->{id}) or return $self->Error('Can`t change order for gallery id='.$self->{id}.' pos='.$position.': '.$sth->errstr);

    my ($newid) = $sth->fetchrow_array;

    my $dth = $db->prepare("UPDATE gallery p1,gallery p2 SET
            p1.gOrder = p1.gOrder + ($position),
            p2.gOrder = p2.gOrder - ($position)
            WHERE p1.id = ? AND p2.id = ?");

    $dth->execute($self->{id},$newid) or return $self->Error('Can`t set order for gallery id='.$self->{id}.' pos='.$position.': '.$sth->errstr);
    
}


sub gd(){
    my $self = shift;
    unless ($self->{_gd}){
    $self->{_gd} = Image::Magick->new();
    $self->{_gd}->Read($gpath.'/'.$self->{name}.'/image_'.$self->{id}.'.png');
    }
    return $self->{_gd};
}

sub wm(){
    my $self = shift;
    unless ($self->{_wm}){
    $self->{_wm} = Image::Magick->new();
    $self->{_wm}->Read($gpath.'/watermark.gif') or warn "watermark read failed";
    }
    return $self->{_wm};
   
}

sub generate(){
    my ($self, $h, $w, $type) = @_;
    return undef unless $self->{name};

    return undef if -r "$gpath/$self->{name}/image_$self->{id}_${h}_${w}.$type";

    my $img = $self->gd;

    my ($wn, $hn, $dh, $dw);
    if ($self->{height} > $h or $self->{width} > $w){
    if ($self->{height} > $self->{width}){
        $dh = $self->{height} / $h;
        $hn = $h;
        $wn = sprintf('%.0f',$self->{width} / $dh);
    }else {
        $dw = $self->{width} / $w;
        $wn = $w;
        $hn = sprintf('%.0f',$self->{height} / $dw);
    }
    }else{
    $wn = $self->{width};
    $hn = $self->{height};
    }
    my $err = $img->Resize(width => $wn, height => $hn);
    if ( -w "$gpath/$self->{name}/") {
    $img->Write("$gpath/$self->{name}/image_$self->{id}_${h}_${w}.$type");
    }
    else {
    $log->fatal("Have not permissions to write file $gpath/$self->{name}/image_$self->{id}_${h}_${w}.$type ");
    }

}

sub path(){
    my $self = shift;
    my $h    = shift;
    my $w    = shift;
    my $type = shift || 'png';
    unless( $h and $w and $type) { return "/gallery/$self->{name}/image_$self->{id}.$type"; }
    unless( -e "$gpath/$self->{name}/image_$self->{id}_${h}_$w.$type"){ $self->generate($h,$w,$type); }

    unless( $h and $w and $type){
	return "/gallery/$self->{name}/image_$self->{id}.$type";
    }
    unless( -e "$gpath/$self->{name}/image_$self->{id}_${h}_$w.$type"){
	$self->generate($h,$w,$type);
    }
    return "/gallery/$self->{name}/image_$self->{id}_${h}_$w.$type";
}

sub path_html_lazy(){
    my $self = shift;
    my $d    = shift;
    
    unless( -e "$gpath/$self->{name}/image_$self->{id}_${d}_$d.jpg"){ $self->generate($d,$d,'jpg'); }

    return '<img data-original="/gallery/'.$self->{name}.'/image_'.$self->{id}.'_'.$d.'_'.$d.'.jpg" src="/img/b.jpg" width="'.$d.'" height="'.$d.'" class="lazy">';
}

sub path_html(){
    my $self = shift;
    my $d    = shift;
    
    unless( -e "$gpath/$self->{name}/image_$self->{id}_${d}_$d.jpg"){ 
        $self->generate($d,$d,'jpg'); 
    }
    return '<img src="/gallery/'.$self->{name}.'/image_'.$self->{id}.'_'.$d.'_'.$d.'.jpg" width="'.$d.'" height="'.$d.'">';
}


sub path_generate(){
    my $self = shift;
    my $d    = shift;
    unless( -e "$gpath/$self->{name}/image_$self->{id}_${d}_$d.jpg"){ return $self->generate($d,$d,'jpg'); }
}


sub _before_delete(){
    my $self = shift;
    my $sth = $db->prepare('UPDATE gallery SET gOrder = gOrder - 1 WHERE gOrder > ? AND name = ? ORDER BY gOrder');
    $sth->execute($self->{gOrder},$self->{name}) ;
    return 1;
}

package Core::Gallery::Image::Default;

use Image::Magick;
our @ISA = qw/Core::Gallery::Image/;

sub new(){
    my $class = shift;
    bless {},$class;
}


sub gd(){
    my $self = shift;
    unless ($self->{_gd}){
    
    $self->{_gd} = Image::Magick->new();
    $self->{_gd}->Read($gpath.'/default.png');

    $self->{width} = $self->{_gd}->Get('width');
    $self->{height} = $self->{_gd}->Get('height');
    }

    return $self->{_gd};
}



sub path(){
    my ($self,$h,$w,$type) = @_;
    unless( $h and $w and $type){
    return "/gallery/default.png";
    }
    $self->generate($h,$w,$type);
    return "/gallery/default_${h}_$w.$type";
}



sub generate(){
    my ($self,$h,$w,$type) = @_;
    return 1 if -r "$gpath/default_${h}_${w}.$type";
    my $img = $self->gd;

    my ($wn,$hn,$dh,$dw);
    $self->{height} = $self->{height} || 0;
    $self->{width} = $self->{height} || 0;
    
    if ($self->{height} > $h or $self->{width} > $w){
    if ($self->{height} > $self->{width}){
        $dh = $self->{height} / $h;
        $hn = $h;
        $wn = sprintf('%.0f',$self->{width} / $dh);
    }else {
        $dw = $self->{width} / $w;
        $wn = $w;
        $hn = sprintf('%.0f',$self->{height} / $dw);
    }
    $img->Resize(width => $wn, height => $hn);
    $img->Write("$gpath/default_${h}_${w}.$type");
    }else{
    $wn = $self->{width};
    $hn = $self->{height};
    my $dimg = Image::Magick->new( size => "${w}x$h");
    $dimg->ReadImage('xc:white');
    $dimg->Composite(image => $img, gravity => 'center');
    
    my $err = $dimg->Write("$gpath/default_${h}_${w}.$type");
    #warn $err;
    }

#    warn "h=$self->{height} w=$self->{width} hn=$hn wn=$wn dh=$dh dw=$dw\n";
}



1;
