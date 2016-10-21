# select distinct(aprp.id),aprt.name, aprs.name, aprp.name, aprp.date_from from apr_types aprt INNER JOIN apr_sections aprs ON aprt.id = aprs.type INNER JOIN apr_contacts as aprc ON aprs.id=aprc.idSection INNER JOIN apr_pages as aprp ON aprp.idCategory = aprs.id where aprc.idCategory = 2 and aprt.alias = 'news' order by aprp.date_from DESC,aprt.id,aprs.id,aprp.name limit 4;
########################################################
package Model::APRTypes;

use Model;
use DB;
our @ISA = qw/Model/;

sub db_table() {'apr_types'};
sub db_columns() {qw/id name title alias Description metakeywords isPublic sort deleted/};
sub db_indexes() {qw/id alias valid/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

sub typesSettings(){
    my $self = shift; $self->{_typesSettings} ||= Model::APRTypesSettings->load($self->{id},'idType');

}
sub list_backoffice(){
    my $self = shift;
    my @buffer;
    my $sth = $db->prepare('SELECT id as id FROM apr_types ORDER BY sort'); $sth->execute(); while (my ($id) = $sth->fetchrow_array){ push @buffer, Model::APRTypes->load($id); }
   
	return \@buffer;
}

sub sections_list(){
    my $self = shift;
    unless ($self->{_sections}){
	my $sth = $db->prepare('SELECT count(aprp.id),
				       aprs.id     
				  FROM apr_types as aprt 
		  	     LEFT JOIN apr_sections aprs ON aprs.type = aprt.id 
			     LEFT JOIN apr_pages aprp ON aprs.id = aprp.idCategory 
			         WHERE aprs.type = ?
			      GROUP BY aprs.id 
			      ORDER BY aprs.sort DESC');
	$sth->execute($self->{id});
	while (my ($count,$idCategory) = $sth->fetchrow_array){
		push @{$self->{_sections}},{section => Model::APRSections->load($idCategory),   scount  => $count  };
	}
    }
    return $self->{_sections};
}

sub sections_list_front(){
    my $self = shift;
    unless ($self->{_sections}){
	my $sth = $db->prepare('SELECT count(aprp.id), 
				       aprs.id 
				  FROM apr_sections as aprs 
			 STRAIGHT_JOIN apr_types aprt 
			            ON aprs.type = aprt.id 
			     LEFT JOIN apr_pages aprp ON aprs.id=aprp.idCategory
			         WHERE aprs.type = ? 
				   AND aprt.isPublic = 1 
				   AND aprs.isPublic = 1 
				   AND aprp.isPublic = 1 
			      GROUP BY aprs.id
			      ORDER BY aprs.sort;');
	$sth->execute($self->{id});
	while (my ($count,$idCategory) = $sth->fetchrow_array){
		push @{$self->{_sections}},{section => Model::APRSections->load($idCategory), scount  => $count  };
	}
    }
    return $self->{_sections};
}

sub frame_types_list() {

    my ($self,$frame) = @_;

    my $order;
    my $kind;
    my $tkind;

    if($frame eq 'top'){
		$kind  = ' AND ats.showInFrame in (1,3)';	 
		$order = ' ORDER BY ats.sortTFrame';
		$tkind = $frame.'types';
    }
    if($frame eq 'bottom'){
		$kind  = ' AND ats.showInFrame in (2,3)';	 
		$order = ' ORDER BY ats.sortBFrame';
		$tkind = $frame.'types';
    }

    my @buffer;
    
    unless ($self->{$tkind}){

	my $sth = $db->prepare('SELECT at.id as id FROM apr_types at INNER JOIN apr_types_settings ats ON at.id = ats.idType WHERE at.isPublic  = 1 '.$kind.' '.$order);
	$sth->execute();
	while (my $item = $sth->fetchrow_hashref) {  push @buffer,Model::APRTypes->load($item->{id}); }

	$self->{$tkind} = \@buffer;
    
    }
    return $self->{$tkind};
}

sub frame_pages_list(){
    my ($self,$frame) = @_;
    my $order;
    my $kind;
    my $tkind;

    if($frame eq 'top'){
	$kind  = ' AND ap.showInFrame in (1,3)';	 
	$order = ' ORDER BY ats.sortTFrame';
	$tkind = $frame.'pages';

    }

    if($frame eq 'bottom'){
	$kind  = ' AND ap.showInFrame in (2,3)';	 
	$order = ' ORDER BY ats.sortBFrame';
	$tkind = $frame.'pages';

    }

    my @buffer;

    unless ($self->{$tkind}){
        $x = 'select ap.id as id 
    				  FROM apr_types apt 
    			 STRAIGHT_JOIN apr_sections aps ON apt.id = aps.type 
    			 STRAIGHT_JOIN apr_pages ap ON aps.id = ap.idCategory 
        		    INNER JOIN apr_types_settings ats ON ats.idType = apt.id 
	    			 WHERE ap.isPublic = 1 '.$kind.'
				 '.$order.'';
    
	    my $xth = $db->prepare($x);	
	    $xth->execute();
	    while (my $xtem = $xth->fetchrow_hashref){
	        push @buffer,Model::APRPages->load($xtem->{id}); 
	    }
	    $self->{$tkind} = \@buffer;
    
    }
    return $self->{$tkind};
}

sub frame_sections_list() {
    my ($self,$frame) = @_;
    my $order;
    my $kind;
    my $tkind;

    if($frame eq 'top'){
	$kind  = ' AND aps.showInFrame in (1,3)';	 
	$tkind = $frame.'sections';
    }

    if($frame eq 'bottom'){
	$kind  = ' AND aps.showInFrame in (2,3)';	 
	$tkind = $frame.'sections';
    }

    my @buffer;

    unless ($self->{$tkind}){
        $x = 'select aps.id as id 
    				  FROM apr_types apt INNER JOIN apr_sections aps ON apt.id = aps.type 
      			 WHERE aps.isPublic = 1 '.$kind.'';
    
	    my $xth = $db->prepare($x);	
	    $xth->execute();
	    while (my $xtem = $xth->fetchrow_hashref){
	        push @buffer,Model::APRSections->load($xtem->{id}); 
	    }
	    $self->{$tkind} = \@buffer;
    
    }
    return $self->{$tkind};
}


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


########################################################
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

########################################################
package Model::APRContacts;

use Model;
use DB;
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

########################################################
package Model::APRTypesSettings;
use Model;
use DB;
our @ISA = qw/Model/;

sub db_table() {'apr_types_settings'};
sub db_columns() {qw/id idType showKind showImgKind showInFrame sortTFrame sortBFrame sortOnPage limitRowsPages deleted/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};



