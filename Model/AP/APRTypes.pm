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
		push @{ $self->{_sections} }, { section => Model::APRSections->load($idCategory),scount  => $count };
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
	
		push @{$self->{_sections}},{ section => Model::APRSections->load($idCategory),	scount  => $count	};
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
	while ( my $item = $sth->fetchrow_hashref ) { push @buffer,Model::APRTypes->load($item->{id}); }
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

1;
