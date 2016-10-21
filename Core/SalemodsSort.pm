package Core::SalemodsSort;
#use warnings;
#use strict;

use Core::DB;
use Core::User;
use Data::Dumper;
use Core::Filters;

sub session_sales_sort(){
    my ($self,$a) = @_;

  		my $user = $a->{user};
  		my $obj  = $user->session->get('sort');

	  	if( $a->{show} || $a->{sort} || $a->{limit} || $a->{brand} || $a->{on_page} ){
	  	  $obj = &session_sales_sort_set_val( $a, $obj );
		}

		if (  !$obj->{sort} ) {
  			$obj->{sort}    = 'price';
		}

		if (  !$obj->{price} ) {
    		$obj->{price}   = 'only_price';
		}

		if (  !$obj->{on_page} ) {
  		  $obj->{on_page} =  $a->{product_list_cols} ?  'cols' : 'list_cols';
		}

	#	else {
		  #$obj = &session_sales_sort_set_def($a,$obj);
	#	}

    $obj->{limit}   		= '124';
    $obj->{cat_id}  		=  $a->{id};
    $obj->{sales_count} 	= &session_sales_sort_count($a);

    $user->session->set('sort' => $obj);
    $user->session->save();

    return $obj;
}

sub session_sales_sort_set_val(){
    my ($a,$obj) = @_;

    if($a->{sort}){
	   $obj->{sort} = $a->{sort};
    }

    if($a->{limit}){
	   $obj->{limit} = $a->{limit};
    }

    if($a->{on_page}){
	   $obj->{on_page} = $a->{on_page};
    }

    if($a->{show}){
	   $obj->{price}       = $a->{show};
	   $obj->{sales_count} = &session_sales_sort_count($a);
    }

    if($a->{brand}){
        $obj->{sales_count} = &session_sales_sort_count($a);
    }

    return $obj;
}

sub session_sales_sort_count(){
    my $a = shift;
    my $q;

    $q  = ' AND price > 0      '                   if $a->{show} eq 'only_price';
    $q .= ' AND isPublic = 1  '                    if $a->{show} eq 'only_price';
    $q .= ' AND idBrand = '.$a->{brand}->{id}.' '  if exists $a->{brand}->{id};

#    print $q ;
    my $sth = $db->prepare('SELECT count( id ) as scount FROM salemods WHERE idCategory = ? '.$q );
    $sth->execute( $a->{id} );
    my $citem = $sth->fetchrow_hashref;
    return $citem->{scount};
}

##########################################
## Refactoring needed.			##
## Must be.				##
## Something like:			##
##########################################

#package Core::SalemodsSortBK;
#use warnings; use strict;
#use Core::DB; use Core::User;

#sub session_sales_sort(){
#    my ( $self, $a ) = @_;
#    my $user = $a->{user};
#    my $obj  = $user->session->get('sort');

#    $obj->{sort}     		= exists $a->{sort}     ?  $a->{sort}     :  'price';
#    $obj->{limit}    		= exists $a->{limit}    ?  $a->{limit}    :  36;
#    $obj->{price}    		= exists $a->{show}     ?  $a->{show}     :  'only_price';
#    $obj->{on_page}  		= exists $a->{on_page}  ?  $a->{on_page}  :  'cols';
#    $obj->{cat_id}  		= $a->{subcategory};
#    $obj->{sales_count} 	= &session_sales_sort_count($a);

#    $user->session->set('sort' => $obj);
#	 $user->session->save();
#    return $obj;
#}

#sub session_sales_sort_count(){
#    my $a = shift;
#    my $q;
#    $q  = ' AND price > 0 '  if $a->{show} eq 'only_price';
#    $q .= ' AND idBrand = '.$a->{brand}->{id}.' ' if exists $a->{brand}->{id};
#    print $q ;
#    my $sth = $db->prepare('SELECT count( id ) as scount FROM salemods WHERE idCategory = ? AND isPublic = 1 '.$q );
#    $sth->execute( $a->{subcategory} );
#    return $sth->fetchrow_hashref;
#}
#1;

1;
