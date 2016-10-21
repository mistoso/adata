package Model::Cloud;

use Model;
use Core::DB;
our @ISA = qw/Model/;

sub db_table() {'cloud'};
sub db_columns() {qw/id name deleted/};
sub db_indexes() {qw/id/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};


sub cloud_items_list(){
	my $self = shift;
	my @buffer;
	
	my $sth = $db->prepare('SELECT * FROM cloud_items WHERE id_cloud = ? ORDER BY deleted, id');
	$sth->execute($self->{id});
	
	while (my $item = $sth->fetchrow_hashref){
	    push @buffer,$item; 
	}
	
	$self->{_cloud_items} = \@buffer;
	return $self->{_cloud_items};
}

sub cloud_items_list_front(){
	my $self = shift;
	my @buffer;
	
	my $sth = $db->prepare('SELECT * FROM cloud_items WHERE id_cloud = ? AND deleted != 1 ORDER BY sort');
	$sth->execute($self->{id});
	
	while (my $item = $sth->fetchrow_hashref){
	    push @buffer,$item; 
	}
	
	$self->{_cloud_items_front} = \@buffer;
	return $self->{_cloud_items_front};
}

sub contacts_by_url(){
	my $self = shift;
	my @buffer;
	
	my $sth = $db->prepare('SELECT * FROM cloud_contacts WHERE id_cloud = ? ORDER BY deleted,id');
	$sth->execute($self->{id});
	
	while (my $item = $sth->fetchrow_hashref){
	    push @buffer,$item; 
	}
	
	$self->{_by_url} = \@buffer;
	return $self->{_by_url};
}


########################################################
package Model::CloudItems;

use Model;
use Core::DB;
our @ISA = qw/Model/;

sub db_table() {'cloud_items'};
sub db_columns() {qw/id id_cloud item_text item_url item_tag item_size item_color item_style sort deleted sep sep_size sep_color sep_style/};
sub db_indexes() {qw/id id_cloud sort/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

########################################################
package Model::CloudContacts;

use Model;
use Core::DB;
our @ISA = qw/Model/;

sub db_table() {'cloud_contacts'};
sub db_columns() {qw/id id_cloud url deleted/};
sub db_indexes() {qw/id id_cloud url/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};



