package Model::Brand;
use Model;
use Core::DB;
use Model::Category;

use Core::User;
use Core::Gallery;

our @ISA = qw/Model/;


sub db_table() {'brands'};
sub db_columns() {qw/id name alias www rusName GalleryName deleted idImage isPublic/};
sub db_indexes() {qw/id/};
sub has_many() 	 {qw/salemods/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub image(){
    my $self = shift;
    $self->{_image} ||= Core::Gallery::Image::Default->new();
    return $self->{_image};
}

#sub gallery(){
#    my $self = shift;
#
#    unless ($self->{_gallery}){
#	use ePortal::Gallery;
#	#load sale gallery
#	$self->{_gallery} = ePortal::Gallery->new($self->{alias});
#    }
#    return $self->{_gallery};
#}

sub salemods_all(){
    my $self = shift;
    my @buf;
    unless ($self->{_salemods_all}){
	my $sth = $db->prepare('SELECT * FROM salemods WHERE idBrand = ? ORDER BY name');
 	$sth->execute($self->{id}) or return $self->Error('Can`t load category childs');
	while (my $item = $sth->fetchrow_hashref){
		push @buf, $item;
	}
	$self->{_salemods_all} = \@buf;
    }
    return $self->{_salemods_all};
}

sub gallery(){
    my $self = shift;
    use Cfg;
    our $gpath = $cfg->{'PATH'}->{'gallery'};
    unless ($self->{_gallery}){
	my $p 	  = "logotip/".$self->{alias};
#	$self->{GalleryName} = $p;
#	$self->save();
	$gpath .= $p;
	my $dir_exist = opendir(DIR,$gpath) or `mkdir -p $gpath`;
	closedir(DIR);
	$self->{_gallery} = Core::Gallery->new($p);
    }
    return $self->{_gallery};
}

sub add_remote_img(){
    my ($self,$file, $fname) = @_;
    my $ngi;
    if($file && $fname){
	my $cysth = $db->prepare('SELECT count(*) FROM gallery where name= ?');
	$cysth->execute($fname);
	my $cngi = $cysth->fetchrow_array;
#      if($cngi < 1){
	use Core::Gallery;
	use Image::Magick;
	use LWP::UserAgent;
	use Cfg;
	my $gpath = $cfg->{'PATH'}->{'gallery'}.''.$fname;
	my $gname = $fname;

	my $ua = LWP::UserAgent->new(agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MyIE2; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',);
	my $r = $ua->get($file);
	my $cnt = $r->content();
	my $dir_exist = opendir(DIR,$gpath) or `mkdir -p $gpath`;
	closedir(DIR);

	my ($name,$format) = ( $file  =~ /(\w+)\.(\w+)$/);
	my $tow = $gpath."/f".$name.".".$format;

	my $aaa = `wget --output-document=$tow $file &`;

	my $img = Image::Magick->new();
	my $x = open FIMG ,$tow;
	$img->Read(file => \*FIMG);
	close FIMG;
	return undef unless $img->Get('width');
	my $model = Core::Gallery::Image->new({
	    name => $fname,
	    width => $img->Get('width'),
	    height => $img->Get('height'),
	});
	$model->save();

	my $ysth = $db->prepare('SELECT max(id) FROM gallery');
	$ysth->execute();
	$ngi = $ysth->fetchrow_array;
	$img->Write("$gpath/image_$ngi.png");
#      }
    }
    return $ngi;
}


sub cat_desc(){
	my $self = shift;
	my @buffer;
	my $sth = $db->prepare('select category.id as cid,
					       count(salemods.id) as scount
					  from brands
				    INNER JOIN salemods ON salemods.idBrand = brands.id
				    INNER JOIN category ON salemods.idCategory = category.id
				         where salemods.idBrand = ?
					   and salemods.isPublic = 1
				      group by category.id
				      order by category.idParent, category.name;');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){ push @buffer, { category => Model::Category->load($item->{cid}), info => $item }; }
	$self->{_cat_count} = \@buffer;
	return $self->{_cat_count};
}

sub front(){
    my $self = shift;
    #$self->{_front} = Model::Brand::FrontPage->load($self->{id},'idBrand') || 0;
    return $self->{_front};
}

sub activ_list(){
    my $self = shift;
    my @buffer;
    unless ($self->{alist}){
        my $sth = $db->prepare('select b.*, UPPER( LEFT(b.name, 1) ) letter from brands b INNER JOIN salemods s ON s.idBrand = b.id where s.isPublic = 1 group by b.id order by b.name');
        $sth->execute();
        while (my $item = $sth->fetchrow_hashref){
            push @buffer,$item;
        }
        $self->{alist} = \@buffer;
    }
    return $self->{alist};
}



1;


