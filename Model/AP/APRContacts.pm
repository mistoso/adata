package Model::APRContacts;

use Model;
use Core::DB;
our @ISA = qw/Model/;

sub db_table() {'apr_contacts'};
sub db_columns() {qw/id idSection idPage idCategory idMod idBrand by_url updated deleted isPublic/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub page(){
    my $self = shift;
    $self->{_page} ||= Model::APRPages->load($self->{idPage});
}

sub gallery(){
    my $self = shift;
    our $gpath = $cfg->{'PATH'}->{'gallery'};
    unless ($self->{_gallery}){
    my $page = Model::APRPages->load($selft->{idPage});
	my $section = Model::APRSections->load($self->{idCategory});
	my $type    = Model::APRTypes->load($section->{type});
	my $p 	  = "apr/$type->{alias}/$self->{alias}";
#	$self->{GalleryName} = $p;
#	$self->save();
	$gpath .= $p;
	my $dir_exist = opendir(DIR,$gpath) or `mkdir -m777 -p $gpath`;
	closedir(DIR);    
	$self->{_gallery} = Core::Gallery->new($p);
    }
    return $self->{_gallery};
}

1;

