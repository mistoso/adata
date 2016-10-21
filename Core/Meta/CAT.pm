package Core::Meta::CAT;
use Model::Meta;
use Model::Category;
use DB;

sub new {
        my $class = shift;
        my $this  = ();
        $this  = bless { }, $class;
	$this->{cat} = Model::Category->load(shift,'alias');

	$this->{cat}->{dec} = $this->{cat}->dec;
	$this->{cat}->{parent} = $this->{cat}->parent;
	$this->{cat}->{parent}->{dec} = $this->{cat}->parent->dec;
	$this->{cat}->{meta} = $this->{cat}->meta;#################

	my $m = Model::Meta->load('category','what');
	if ($m) {
		$this->{position}->{title} = $m->{title};
		$this->{position}->{description} = $m->{description};
		$this->{position}->{keywords} = $m->{keywords};
        $this->{position}->{f_block_left} = $m->{f_block_left};
        $this->{position}->{s_block} = $m->{s_block};
        $this->{position}->{f_block_right} = $m->{f_block_right};
	}
	else {
		$this->{position}->{title} = '';
		$this->{position}->{description} = '';
		$this->{position}->{keywords} = '';
        $this->{position}->{f_block_left} = '';
        $this->{position}->{s_block} = '';
        $this->{position}->{f_block_right} = '';
	}
	return $this;
}

sub getTitle {
	my $this = shift;

	unless ($this->{title}) {
		
		my $dec = $this->{cat}->{dec};
		my $parent = $this->{cat}->{parent};
		
		#################
		my $parent_dec = $this->{cat}->{parent}->{dec};
		my $meta = $this->{cat}->{meta};
		#################

		###########
		my $one;
		if( $dec->{one} ) { $one = $dec->{one};
		} else { $one = $this->{cat}->{name}; }
		##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}
		else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}
		else{$kogoOne = $this->{cat}->{name};}
    	my $kogoMany;
    	if
    	( $dec->{kogoMany} ) 
    	{ $kogoMany = $dec->{kogoMany }; } 
    	else 
    	{ $kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}
		else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}
		else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}
		else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}
		else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}
    		else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}
		else{$parent_naOne = $parent->{name};}

		$this->{title} = $this->{position}->{title};

		$this->{title} =~ s/%{title}/$meta->{title}/g;
		$this->{title} =~ s/%{metaKeywords}/$meta->{metaKeywords}/g;
		$this->{title} =~ s/%{metaDescription}/$meta->{metaDescription}/g;

		$this->{title} =~ s/%{name}/$this->{cat}->{name}/g;
		$this->{title} =~ s/%{name_parent}/$parent->{name}/g;
		$this->{title} =~ s/%{one}/$one/g;
		$this->{title} =~ s/%{many}/$many/g;
		$this->{title} =~ s/%{kogoOne}/$kogoOne/g;
		$this->{title} =~ s/%{kogoMany}/$kogoMany/g;
		$this->{title} =~ s/%{naOne}/$naOne/g;

		$this->{title} =~ s/%{parent_one}/$parent_one/g;
		$this->{title} =~ s/%{parent_many}/$parent_many/g;
		$this->{title} =~ s/%{parent_kogoOne}/$parent_kogoOne/g;
		$this->{title} =~ s/%{parent_kogoMany}/$parent_kogoMany/g;
		$this->{title} =~ s/%{parent_naOne}/$parent_naOne/g;
	}
	return $this->{title};
}

sub getDescription {
	my $this = shift;
	unless ($this->{description}) {
		my $dec = $this->{cat}->{dec};
		my $parent = $this->{cat}->{parent};
		
		#################
		my $parent_dec = $this->{cat}->{parent}->{dec};
		my $meta = $this->{cat}->{meta};
		#################

###########
		my $one     = $dec->{one}     ? $dec->{one}     : $this->{cat}->{name};
		my $many    = $dec->{many}    ? $dec->{many}    : $this->{cat}->{name};
		my $kogoOne = $dec->{kogoOne} ? $dec->{kogoOne} : $this->{cat}->{name};


    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}
    		else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}
		else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}
		else{$parent_one = $parent->{name};}
##########
		
		
		my $parent_many = $parent_dec->{many} ? $parent_dec->{many} : $parent->{name};

##########

		my $parent_kogoOne;
		
		if( $parent_dec->{kogoOne} ) {
			$parent_kogoOne = $parent_dec->{kogoOne};
		} else {
			$parent_kogoOne = $parent->{name};
		}

##########

    	my $parent_kogoMany;
    	if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}
    	else{$parent_kogoOne = $parent->{name};}

##########

		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}
		else{$parent_naOne = $parent->{name};}

  	    $this->{description} = $this->{position}->{description};
		$this->{description} =~ s/%{title}/$meta->{title}/g;
		$this->{description} =~ s/%{metaKeywords}/$meta->{metaKeywords}/g;
		$this->{description} =~ s/%{metaDescription}/$meta->{metaDescription}/g;
		$this->{description} =~ s/%{name}/$this->{cat}->{name}/g;
		$this->{description} =~ s/%{name_parent}/$parent->{name}/g;
		my $one     = $dec->{one}     ? $dec->{one}     : $this->{cat}->{name};

		$this->{description} =~ s/%{one}/$one/g;
		$this->{description} =~ s/%{many}/$many/g;
		$this->{description} =~ s/%{kogoOne}/$kogoOne/g;
		$this->{description} =~ s/%{kogoMany}/$kogoMany/g;
		$this->{description} =~ s/%{naOne}/$naOne/g;
		$this->{description} =~ s/%{parent_one}/$parent_one/g;
		$this->{description} =~ s/%{parent_many}/$parent_many/g;
		$this->{description} =~ s/%{parent_kogoOne}/$parent_kogoOne/g;
		$this->{description} =~ s/%{parent_kogoMany}/$parent_kogoMany/g;
		$this->{description} =~ s/%{parent_naOne}/$parent_naOne/g;

	}
return $this->{description};
}

sub getKeywords {
	my $this = shift;
	unless ($this->{keywords} ) {
		my $dec = $this->{cat}->{dec};
		my $parent = $this->{cat}->{parent};#################
		my $parent_dec = $this->{cat}->{parent}->{dec};
		my $meta = $this->{cat}->{meta};#################
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}
		else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}
		else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}
		else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}
    		else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}
		else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}
		else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}
		else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}
		else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}
    		else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}
		else{$parent_naOne = $parent->{name};}

		$this->{keywords} = $this->{position}->{keywords};
		$this->{keywords} =~ s/%{title}/$meta->{title}/g;
		$this->{keywords} =~ s/%{metaKeywords}/$meta->{metaKeywords}/g;
		$this->{keywords} =~ s/%{metaDescription}/$meta->{metaDescription}/g;
		$this->{keywords} =~ s/%{name}/$this->{cat}->{name}/g;
		$this->{keywords} =~ s/%{name_parent}/$parent->{name}/g;
		$this->{keywords} =~ s/%{one}/$one/g;
		$this->{keywords} =~ s/%{many}/$many/g;
		$this->{keywords} =~ s/%{kogoOne}/$kogoOne/g;
		$this->{keywords} =~ s/%{kogoMany}/$kogoMany/g;
		$this->{keywords} =~ s/%{naOne}/$naOne/g;
		$this->{keywords} =~ s/%{parent_one}/$parent_one/g;
		$this->{keywords} =~ s/%{parent_many}/$parent_many/g;
		$this->{keywords} =~ s/%{parent_kogoOne}/$parent_kogoOne/g;
		$this->{keywords} =~ s/%{parent_kogoMany}/$parent_kogoMany/g;
		$this->{keywords} =~ s/%{parent_naOne}/$parent_naOne/g;
	}
	return $this->{keywords};
}

sub getF_block_left {
	my $this = shift;

	unless ($this->{f_block_left}) {
		my $dec = $this->{cat}->{dec};
		my $parent = $this->{cat}->{parent};#################
		my $parent_dec = $this->{cat}->{parent}->{dec};
		my $meta = $this->{cat}->{meta};#################

###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}
		else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}
		else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}
		else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}
    		else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}
		else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}
		else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}
		else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}
		else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}
    		else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}
		else{$parent_naOne = $parent->{name};}

		$this->{f_block_left} = $this->{position}->{f_block_left};

		$this->{f_block_left} =~ s/%{title}/$meta->{title}/g;
		$this->{f_block_left} =~ s/%{metaKeywords}/$meta->{metaKeywords}/g;
		$this->{f_block_left} =~ s/%{metaDescription}/$meta->{metaDescription}/g;

		$this->{f_block_left} =~ s/%{name}/$this->{cat}->{name}/g;
		$this->{f_block_left} =~ s/%{name_parent}/$parent->{name}/g;
		$this->{f_block_left} =~ s/%{one}/$one/g;
		$this->{f_block_left} =~ s/%{many}/$many/g;
		$this->{f_block_left} =~ s/%{kogoOne}/$kogoOne/g;
		$this->{f_block_left} =~ s/%{kogoMany}/$kogoMany/g;
		$this->{f_block_left} =~ s/%{naOne}/$naOne/g;

		$this->{f_block_left} =~ s/%{parent_one}/$parent_one/g;
		$this->{f_block_left} =~ s/%{parent_many}/$parent_many/g;
		$this->{f_block_left} =~ s/%{parent_kogoOne}/$parent_kogoOne/g;
		$this->{f_block_left} =~ s/%{parent_kogoMany}/$parent_kogoMany/g;
		$this->{f_block_left} =~ s/%{parent_naOne}/$parent_naOne/g;
        
        if (($this->{f_block_left} eq ' ') || ($this->{f_block_left} eq '')){
            my $sth = $db->prepare('SELECT left_block from default_footer_block');
            $sth->execute();
            $this->{f_block_left} = $sth->fetchrow_array();
        }
	}
	return $this->{f_block_left};
}

sub getS_block {
	my $this = shift;

	unless ($this->{s_block}) {
		my $dec = $this->{cat}->{dec};
		my $parent = $this->{cat}->{parent};#################
		my $parent_dec = $this->{cat}->{parent}->{dec};
		my $meta = $this->{cat}->{meta};#################

###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}
		else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}
		else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}
		else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}
    		else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}
		else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}
		else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}
		else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}
		else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}
    		else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}
		else{$parent_naOne = $parent->{name};}

		$this->{s_block} = $this->{position}->{s_block};

		$this->{s_block} =~ s/%{title}/$meta->{title}/g;
		$this->{s_block} =~ s/%{metaKeywords}/$meta->{metaKeywords}/g;
		$this->{s_block} =~ s/%{metaDescription}/$meta->{metaDescription}/g;

		$this->{s_block} =~ s/%{name}/$this->{cat}->{name}/g;
		$this->{s_block} =~ s/%{name_parent}/$parent->{name}/g;
		$this->{s_block} =~ s/%{one}/$one/g;
		$this->{s_block} =~ s/%{many}/$many/g;
		$this->{s_block} =~ s/%{kogoOne}/$kogoOne/g;
		$this->{s_block} =~ s/%{kogoMany}/$kogoMany/g;
		$this->{s_block} =~ s/%{naOne}/$naOne/g;

		$this->{s_block} =~ s/%{parent_one}/$parent_one/g;
		$this->{s_block} =~ s/%{parent_many}/$parent_many/g;
		$this->{s_block} =~ s/%{parent_kogoOne}/$parent_kogoOne/g;
		$this->{s_block} =~ s/%{parent_kogoMany}/$parent_kogoMany/g;
		$this->{s_block} =~ s/%{parent_naOne}/$parent_naOne/g;
        
        if (($this->{s_block} eq ' ') || ($this->{s_block} eq '')){
            my $sth = $db->prepare('SELECT centr_block from default_footer_block');
            $sth->execute();
            $this->{s_block} = $sth->fetchrow_array();
        }
	}
	return $this->{s_block};
}

sub getF_block_right {
	my $this = shift;

	unless ($this->{f_block_right}) {
		my $dec = $this->{cat}->{dec};
		my $parent = $this->{cat}->{parent};#################
		my $parent_dec = $this->{cat}->{parent}->{dec};
		my $meta = $this->{cat}->{meta};#################

###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}
		else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}
		else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}
		else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}
    		else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}
		else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}
		else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}
		else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}
		else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}
    		else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}
		else{$parent_naOne = $parent->{name};}

		$this->{f_block_right} = $this->{position}->{f_block_right};
		$this->{f_block_right} =~ s/%{title}/$meta->{title}/g;
		$this->{f_block_right} =~ s/%{metaKeywords}/$meta->{metaKeywords}/g;
		$this->{f_block_right} =~ s/%{metaDescription}/$meta->{metaDescription}/g;

		$this->{f_block_right} =~ s/%{name}/$this->{cat}->{name}/g;
		$this->{f_block_right} =~ s/%{name_parent}/$parent->{name}/g;
		$this->{f_block_right} =~ s/%{one}/$one/g;
		$this->{f_block_right} =~ s/%{many}/$many/g;
		$this->{f_block_right} =~ s/%{kogoOne}/$kogoOne/g;
		$this->{f_block_right} =~ s/%{kogoMany}/$kogoMany/g;
		$this->{f_block_right} =~ s/%{naOne}/$naOne/g;

		$this->{f_block_right} =~ s/%{parent_one}/$parent_one/g;
		$this->{f_block_right} =~ s/%{parent_many}/$parent_many/g;
		$this->{f_block_right} =~ s/%{parent_kogoOne}/$parent_kogoOne/g;
		$this->{f_block_right} =~ s/%{parent_kogoMany}/$parent_kogoMany/g;
		$this->{f_block_right} =~ s/%{parent_naOne}/$parent_naOne/g;
        
        if (($this->{f_block_right} eq ' ') || ($this->{f_block_right} eq '')){
            my $sth = $db->prepare('SELECT right_block from default_footer_block');
            $sth->execute();
            $this->{f_block_right} = $sth->fetchrow_array();
        }
	}
	return $this->{f_block_right};
}
1;
