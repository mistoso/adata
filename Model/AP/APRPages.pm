package Model::APRPages;

use Model;
use DB;
use Core::Gallery;
use Cfg;

our @ISA = qw/Model/;

sub db_table() {'apr_pages'};
sub db_columns() {qw/id idCategory name title alias Description metakeywords page_text date_from date_to idImage GalleryName isPublic sort updated deleted showInFrame isCommented/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub section(){
    my $self = shift;
    $self->{_section} ||= Model::APRSections->load($self->{idCategory});
}

###
sub image(){
    my $self = shift;
    unless ($self->{_image}){
	$self->{_image} = Core::Gallery::Image::Default->new();
    }
    $self->{_image};
}

sub gallery(){
    my $self = shift;
    our $gpath = $cfg->{'PATH'}->{'gallery'};
    unless ($self->{_gallery}){
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
###

sub contacts_category(){
	my $self = shift;
	my @buffer;
	unless ($self->{_contacts}){
		my $sth = $db->prepare('SELECT ac.id as id,
					       ac.isPublic as isPublic,
					       c.id as idCategory, 
					       c.name as cname
					  FROM apr_contacts ac 
				    INNER JOIN category c ON ac.idCategory = c.id 
				         WHERE ac.idPage = ? 
					   AND c.isPublic = 1
					   AND c.deleted != 1
                        AND ac.deleted != 1  
			 	      ORDER BY c.name');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){
		    push @buffer,$item; 
		}
		$self->{_contacts} = \@buffer;
	}
	return $self->{_contacts};
}
sub contacts_mods(){
	my $self = shift;
	my @buffer;
	unless ($self->{_mods}){
		my $sth = $db->prepare('SELECT aprc.id as id,
					       s.id as idMod, 
					       s.name as name,
					       aprc.isPublic as isPublic
					  FROM apr_contacts aprc INNER JOIN salemods s ON aprc.idMod = s.id  
					 WHERE idPage = ?
                     AND aprc.deleted != 1
                    AND s.deleted != 1
				      ORDER BY s.name');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){
		    push @buffer,$item; 
		}
		$self->{_mods} = \@buffer;
	}
	return $self->{_mods};
}

sub contacts_by_url(){
	my $self = shift;
	my @buffer;
	unless ($self->{_by_url}){
		my $sth = $db->prepare('SELECT id,
					       by_url,
					       deleted
					  FROM apr_contacts
					 WHERE idPage = ? and by_url !="0"
				      ORDER BY id');
		$sth->execute($self->{id});
		while (my $item = $sth->fetchrow_hashref){
		    push @buffer,$item; 
		}
		$self->{_by_url} = \@buffer;
	}
	return $self->{_by_url};
}


sub update_page_section(){
	my ( $self, $idSection, $from, $to ) = @_;
	if( $from && $to && $idSection != $self->{$idSection} ){

	    my $ffrom  = $cfg->{'PATH'}->{'gallery'}.''.$from; 
	    my $fto    = $cfg->{'PATH'}->{'gallery'}.''.$to; 
	    my $ftodir = $fto.'/'.$self->{alias}; 
	    
	    warn "\n\n from - $ffrom , to - $ftodir, from name - $from , to name - $to, idSection - $idSection \n\n";
	    if( opendir(DIR,$ffrom) ){
		closedir(DIR);
		my $dir_exist = opendir(DIR,$ftodir) or `mkdir -m777 -p $ftodir`;
		closedir(DIR);    
		warn "\n\n move From - $ffrom ---> To - $ftodir! Done. \n\n";
		`mv $ffrom/* $ftodir`;
	    } else {
		warn "don't move anything! From - $ffrom - not exist... OR To - $ftodir - already exist";
	    }
	    if( opendir(DIR,$ftodir) && $idSection ){
		closedir(DIR);   
		$to .= '/'.$self->{alias};
		my $sth = $db->prepare('update gallery set name = ? where name = ?;');
		$sth->execute($to,$from);
		$self->{idCategory}  = $idSection;
		$self->{GalleryName} = $to;	
		$self->save();
	    } else {
		warn "can't open directory ftodir or idSection - $idSection wrong!";
	    }
	} else {
	    warn "\n\n WRONG. from - $ffrom , to - $fto, from name - $from , to name - $to, idSection - $idSection \n\n";
	}
}

sub comments(){
    my $self = shift;
    $self->{comments} ||= Model::Comment->comments_for('apr_pages',$self->{'id'});
    return $self->{comments};
}
