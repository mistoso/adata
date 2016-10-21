package Model::Competitor;

use strict; use warnings;
use Model;  our @ISA = qw/Model/;

use Core::DB;
use Model::Category; 
use Model::SaleMod;

sub db_table(){'competitors'};
sub db_columns(){qw/id name table_name enc isPublic/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub listprice(){
    my $self = shift;

    my $h = $db->prepare('SELECT id, idMod 
			                       FROM competitors_prices 
			                      WHERE idCompetitor = ? 
		       	                  AND idMod IS NOT NULL 
			                        AND cat_id IS NOT NULL'); 
    $h->execute($self->{id}); my @b = ();
    while( my ( $id, $idMod ) = $h->fetchrow_array ) {
      	
      	my $eh = $db->prepare('SELECT price FROM salemods WHERE id = ?'); 
      	$eh->execute( $idMod ); 
		my $sprice = $eh->fetchrow_array( );  
		
		my $itm = Model::Competitor::Price->load( $id );
		$itm->{subprice} = sprintf( '%d', $sprice - $itm->{price} );

		push @b, $itm;
    }
    my @buf = sort { $b->{subprice} <=> $a->{subprice} } @b if @b;
    return \@buf;
}

sub cat_list(){
  my $self = shift;
  my @b;
  my $h = $db->prepare( 'SELECT * 
			   FROM competitors_parse 
			  WHERE comp_id = ?' );
  $h->execute( $self->{id} );

  while (my $item = $h->fetchrow_hashref) { 
	push @b, Model::Competitor::Parse->load( $item->{id} ); 
  }

  return \@b;
}

package Model::Competitor::Parse;

use strict; use warnings;
use Model;  our @ISA = qw/Model/;
use Core::DB; 

use Core::Competitor; 
use LWP::UserAgent; 


sub db_table(){'competitors_parse'};
sub db_columns(){qw/id comp_id cat_id link listlink words paged isPublic/};

sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub listprice_new(){
    my $self = shift;

    my $h = $db->prepare('SELECT id from competitors_prices where idCompetitor = ? AND cat_id = ?'); 
    $h->execute( $self->{comp_id}, $self->{cat_id}); my @b = (); 

    while ( my $l = $h->fetchrow_hashref ){ 
      push @b, Model::Competitor::Price->load( $l->{id} ); 
    } 
    return  \@b;
}
sub listprice_link(){
    my $self = shift;
    
    my $h = $db->prepare('SELECT id FROM competitors_prices WHERE idCompetitor = ? AND cat_id = ? AND idMod IS NOT NULL');
    $h->execute( $self->{comp_id}, $self->{cat_id} ); 
    my @b = ();
	  
    while (my $itm = $h->fetchrow_hashref){
        push @b,Model::Competitor::Price->load($itm->{id});
    }
    return  \@b;
}
sub parse(){
   
    use Data::Dumper;
   
    my $self = shift;
    my $parser = $self->competitor->{table_name};
    my $mod = Core::Competitor->new( $self );


#    foreach my $item (@{ Core::Competitor->new( $self ) }){

        #Model::Competitor::Price->update_price( $item->{href}, $item->{name}, $item->{price}, $self->{comp_id}, $self->{cat_id} );
#    }

}
sub competitor(){
	my $self = shift;
	$self->{_competitor} 
  ||= Model::Competitor->load($self->{comp_id});
}

sub category(){
	my $self = shift;
	$self->{_category} 
  ||= Model::Category->load($self->{cat_id});
}

package Model::Competitor::Price;

use strict; use warnings;
use Model;  our @ISA = qw/Model/;
use Core::DB;

sub db_table(){'competitors_prices'};
sub db_columns(){qw/id idCompetitor idMod idCompMod cat_id compModName price updated/};
sub _check_columns_values(){1};
sub _check_write_permissions(){1};

sub update_price(){
	my($self, $id, $name, $price, $comp_id, $cat_id) = @_;

	my $h = $db->prepare('SELECT idMod, price FROM competitors_prices WHERE idCompetitor = ? AND idCompMod = ?');
	$h->execute( $comp_id, $id );

    my $item = $h->fetchrow_hashref();

    if($price != $item->{price}){

        $h = $db->prepare('REPLACE competitors_prices SET idCompetitor = ?, idCompMod = ?, compModName = ?, price = ?, idMod = ?, cat_id = ?, updated = NOW()');
        $h->execute($comp_id, $id, $name, $price, $item->{idMod}, $cat_id);

    }
}
sub fixcode(){
	my ( $self, $idMod ) = @_;  

	my $h = $db->prepare('UPDATE competitors_prices SET idMod = ? WHERE id = ?');
    	$h->execute( $idMod, $self->{id} );
}

sub salemod(){ 
	my $self = shift; 

	$self->{_salemod} 
	||= Model::SaleMod->load($self->{idMod}); 
}

1;

