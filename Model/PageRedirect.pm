package Model::PageRedirect;

use Model;
use Core::DB;
our @ISA = qw/Model/;

sub db_table() {'page_redirect'};
sub db_columns() {qw/id lfr lto deleted/};
sub db_indexes() {qw/id lfr lto/};

sub _check_write_permissions(){1};
sub _check_columns_values(){1};

#sub contacts_by_url(){
#	my $self = shift;
#	my @buffer;
#	my $sth = $db->prepare('SELECT * FROM cloud_contacts WHERE id_cloud = ? ORDER BY deleted,id');
#	$sth->execute($self->{id});
#	while (my $item = $sth->fetchrow_hashref){
#	    push @buffer,$item; 
#	}
#	$self->{_by_url} = \@buffer;
#	return $self->{_by_url};
#}

