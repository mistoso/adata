package Core::Filters;

use DB;
use Core::User;
use Data::Dumper;
use Model;
use Model::Filter;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self->{category} = shift;
    $self;
}

sub set_mask_table_name {
    my $self = shift; $self->{tmp_table} = shift;
}


sub get_unset_brands {
    my $self = shift;
    my $category = $self->{category};

    unless ($self->{__unset_brands}){

        my $user     = Core::User->current();
        my $filters  = $user->session->get('filters_brands');

	my $ext_sql;	

	if ($self->{tmp_table} && !$self->get_set_brands()){
	    $ext_sql = ' INNER JOIN '.$self->{tmp_table}.' as t ON sm.id = t.idSalemod ';
	}
	    my $sth ="SELECT 		b.name as name,
			  	  	  b.id as id,
			  	   b.alias as alias,
	count(distinct(sm.id)) as bcount
				      FROM salemods as sm  ".$ext_sql."
			    INNER JOIN brands as b ON b.id = sm.idBrand 
				     WHERE sm.idCategory = ?

				       AND sm.isPublic = 1
				       AND sm.price > 0
				       AND b.deleted != 1
			             GROUP BY b.id ORDER BY b.name
			             
			            "; 
	
	my @buffer;
	$sth = $db->prepare($sth);    
	$sth->execute($category);
	while (my $filter = $sth->fetchrow_hashref){
            if ($filters->{$category}->{$filter->{id}}) {
		    $filter->{set} = '1';
	    }
	    push @buffer,$filter;
	}
	$self->{__unset_brands} = \@buffer;
    }
    return $self->{__unset_brands};
}


sub get_unset {
    my $self = shift;
    my $category = $self->{category};
    unless ($self->{__unset}) {
        my $user     = Core::User->current();
        my $filters  = $user->session->get('filters');
#	my $model = Model::Category->load($category);
        my $sth = $db->prepare("select * from feature_groups where public and not deleted and searchable and idCategory = ? order by orderby");
        $sth->execute($category);
        while (my $feature = $sth->fetchrow_hashref()) {
	    my $feature_where = $self->get_set_parent($feature->{id});
	    my $query;
	    my $csth;

	    if ($self->{tmp_table} && $feature_where != 0) {
		$query = "select f.*, concat('+',count(sm.id)) as smcount from filters f inner join filters_cache fc ON f.id = fc.idFilter LEFT JOIN $self->{tmp_table} t ON t.idSaleMod  = fc.idSalemod left JOIN salemods sm ON sm.id = fc.idSalemod where f.idParent = ? and sm.idCategory = ? and sm.price > 0 and sm.isPublic = 1 group by f.id order by f.orderby";
        	$csth = $db->prepare($query);
		$csth->execute($feature->{id},$category);
	    }

	    if ($self->{tmp_table} && $feature_where == 0) {
		$query = "select f.*, count(sm.id) as smcount from filters f inner join filters_cache fc ON f.id = fc.idFilter INNER JOIN $self->{tmp_table} t ON t.idSaleMod  = fc.idSalemod INNER JOIN salemods sm ON sm.id = fc.idSalemod where f.idParent = ? and sm.idCategory = ? and sm.price > 0 and sm.isPublic = 1 group by f.id order by f.orderby";

        	$csth = $db->prepare($query);
		$csth->execute($feature->{id},$category);
	    } 

	    if (!$self->{tmp_table} && $feature_where == 0) {
        	$query = "select f.*, count(fc.idSalemod) as smcount from filters f inner join filters_cache fc ON f.id = fc.idFilter INNER JOIN salemods sm ON sm.id = fc.idSalemod where f.idParent = ? and sm.idCategory = ? group by f.id order by f.orderby";
        	$csth = $db->prepare($query);
		$csth->execute($feature->{id},$category);
	    }

            my @tmp = ();

            while (my $filter = $csth->fetchrow_hashref()) {
                if ($filters->{$category}->{$filter->{id}}) {
		    $filter->{set} = '1';
		}
                push @tmp,$filter;
            }

            if ( scalar(@tmp) > 0 ) {
                $feature->{filters} = \@tmp;
                push @{$self->{__unset}},$feature;
            }
        }

    }
    return @{$self->{__unset}};
}

#####PEREDEL NA GET SET NIZHE
sub get_set_parent {
    my $self = shift;
    my $parent_id = shift;
    my $user     = Core::User->current();
    my $filters = $user->session->get('filters');
    my $vkl_kak_i_magazin = 0;

    my $sth = $db->prepare("select id as id from filters where idParent = ? order by orderby");
    $sth->execute($parent_id);

    while (my $feature = $sth->fetchrow_hashref()){
	foreach $key (keys %{$filters->{$self->{category}}}) {

	    if($key == $feature->{id}){
		$vkl_kak_i_magazin = $feature->{id};
	    }

	}
    }

    return $vkl_kak_i_magazin;
}




sub get_set {
    my $self = shift;
    my $category  = $self->{category};

    unless ($self->{__set}) {
        my $user = Core::User->current();
        my $filters = $user->session->get('filters');

        my $ids = '';
        foreach $key (keys %{$filters->{$category}}) {
            $ids .= "$key,";
        }
        $ids =~ s/,$//g;

        if ($ids) {
            my $psth = $db->prepare("select distinct(idParent) from filters where id in ($ids)");
            $psth->execute();
            while (my ($idParent) = $psth->fetchrow_array()) {
                my $sth = $db->prepare("select * from feature_groups where id = ?");
                $sth->execute($idParent);
                while (my $feature = $sth->fetchrow_hashref()) {
                    my $csth = $db->prepare("select * from filters where idParent = ?  and id in ($ids) order by orderby");
                    $csth->execute($feature->{id});
                    my @tmp = ();
                    while (my $filter = $csth->fetchrow_hashref()) {
                        push @tmp,$filter;
                    
                    }
                    $feature->{filters} = \@tmp;
                    push @{$self->{__set}}, $feature;
                }
            }        

        }
    }
    return @{$self->{__set}};
}






sub get_set_brands {
    my $self = shift;
    my $category  = $self->{category};
    my $ids;
    my $user = Core::User->current();
    my $filters = $user->session->get('filters_brands');
    my $ids = '';
    foreach $key (keys %{$filters->{$category}}) {
	$ids .= "$key,";
    }
    $ids =~ s/,$//g;
    return $ids;
}


sub set {
    my $self = shift;
    my $category  = $self->{category};
    my $action = shift;
    my $feature_id = shift;
    my $sess_val = 'filters'; 
    my $user = Core::User->current();

    if ($action eq 'add_brand' || $action eq 'del_brand') {
	$sess_val = 'filters_brands';
    }

    my $filters  = $user->session->get($sess_val);

    if (($action eq 'add' or $action eq 'add_brand') and $feature_id =~ /^\d+$/) {
        $filters->{$category}->{$feature_id} = 1;
#        $filters->{$category}->{}->{$feature_id} = 1;
    }

    elsif (($action eq 'del' or $action eq 'del_brand') and $feature_id =~ /^\d+$/) {
	delete $filters->{$category}->{$feature_id};
#        $filters->{$category.'_'.$action}->{$feature_id} = 1;
    }
    elsif ($action eq 'delall') {
        delete $filters->{$category};
    }
    $user->session->set($sess_val => $filters);
    $user->session->save();

}

sub get_sql_join {
    my $self = shift;
    return $self->{__sql}->{inner_join} if $self->{__sql}->{inner_join};
}


sub get_sql_join {
    my $self = shift;
    return $self->{__sql}->{inner_join} if $self->{__sql}->{inner_join};
}

sub get_sql_where {
    my $self = shift;
    return $self->{__sql}->{where} if $self->{__sql}->{where};
}

sub set_sql {
    my $self = shift;

    my @features = $self->get_set();

    $self->{__sql}->{inner_join} = '';
    $self->{__sql}->{where} = '';

    my $count = 0;

    foreach $feature (@features) {

        $count += 1;
        $self->{__sql}->{inner_join} .= ' inner join filters_cache cf'.$count.' on s.id = cf'.$count.'.idSaleMod';
        my @filter = ();

        foreach $filter_hash (@{$feature->{filters}}){
            push @filter,$filter_hash->{id};
	    my @filter = ();
        }

        if (scalar @filter > 0) {
            $self->{__sql}->{where} .= " and cf$count.idFilter in(".join(',',@filter).") ";
        }
    }

    if($self->get_set_brands()){
        $self->{__sql}->{where} .= ' and s.idBrand in('.$self->get_set_brands().') ';
    }
}

1;
