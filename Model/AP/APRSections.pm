########################################################
package Model::APRSections;

use Model;
use DB;
use Core::Gallery;
use Cfg;

our @ISA = qw/Model/;

sub db_table() {'apr_sections'};
sub db_columns() {qw/id name type title alias metakeywords Description idImage GalleryName isPublic sort updated deleted isCommented showInFrame/};
sub db_indexes() {qw/id alias type sort/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};


sub front_pages(){
    my ($self, $limit) = @_;
    if($limit){
        $limit = ' limit '.$limit;
    }else{
        $limit = ' limit 0,30';
    }
    unless ($self->{_pages}){
        my $sth = $db->prepare('SELECT id FROM apr_pages WHERE idCategory = ? and isPublic = 1 and not deleted order by date_from DESC, sort'.$limit);
        $sth->execute($self->{id});
        while (my ( $id, $count ) = $sth->fetchrow_array){
            push @{$self->{_pages}},Model::APRPages->load($id);
        }
    }
    return $self->{_pages};
}

sub pages(){
	
	my ($self, $limit) = @_;

	if($limit){
	
	    $limit = ' limit '.$limit;
	
	}else{
	
	    $limit = ' limit 0,30';
	}

	unless ($self->{_pages}){
	
		my $sth = $db->prepare('SELECT id FROM apr_pages WHERE idCategory = ? and not deleted order by date_from DESC, sort'.$limit);
		$sth->execute($self->{id});
	
		while (my ( $id, $count ) = $sth->fetchrow_array){
			push @{$self->{_pages}},Model::APRPages->load($id);
		}
	
	}
	return $self->{_pages};
}

sub pages_count(){
	my $self = shift;
	my $sth = $db->prepare('SELECT count(id) FROM apr_pages WHERE idCategory = ?');
	$sth->execute($self->{id});
	my $count = $sth->fetchrow_array;
	return $count;
}
sub contacts_category(){
	my $self = shift;
	my @buffer;
	unless ($self->{_contacts}){
		my $sth = $db->prepare('SELECT ac.id as id,
					       ac.deleted as deleted,
					       c.id as idCategory, 
					       c.name as cname
					  FROM apr_contacts ac 
				    INNER JOIN category c ON ac.idCategory = c.id 
				         WHERE ac.idSection = ? 
					   AND c.isPublic = 1
					   AND c.deleted != 1
			 	      ORDER BY c.name');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){
		    push @buffer,$item; 
		}
		$self->{_contacts} = \@buffer;
	}
	return $self->{_contacts};
}

sub contacts_brands(){
	my $self = shift;
	my @buffer;
	unless ($self->{_contacts_brands}){
		my $sth = $db->prepare('SELECT ac.id as id,
					       ac.deleted as deleted,
					       b.id as idBrand, 
					       b.name as bname
					  FROM apr_contacts ac 
				    INNER JOIN brands b ON ac.idBrand = b.id 
				         WHERE ac.idSection = ? 
					   AND b.deleted != 1
			 	      ORDER BY b.name');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){
		    push @buffer,$item; 
		}
		$self->{_contacts_brands} = \@buffer;
	}
	return $self->{_contacts_brands};
}
sub types(){
	my $self = shift; $self->{_types} ||= Model::APRTypes->list();
}
sub load_type(){
	my $self = shift; $self->{_load_type} ||= Model::APRTypes->load($self->{type});
}

###

sub image(){
    my $self = shift; $self->{_image} ||= Core::Gallery::Image::Default->new();
}

sub gallery(){
    my $self = shift;
    our $gpath = $cfg->{'PATH'}->{'gallery'};
    unless ($self->{_gallery}){
	my $type = Model::APRTypes->load($self->{type});

	my $p 	  = "apr/$type->{alias}-$self->{alias}";
#	$self->{GalleryName} = $p;
#	$self->save();
	$gpath .= $p;
	my $dir_exist = opendir(DIR,$gpath) or `mkdir -m777 -p $gpath`;
	closedir(DIR);    
	$self->{_gallery} = Core::Gallery->new($p);
    }
    return $self->{_gallery};
}
###


sub disallow_add_comments(){
    my $self = shift;
    my $sth = $db->prepare("update apr_pages set isCommented = '0' WHERE idCategory = ?");
    return $sth->execute($self->{id});
}

1;
