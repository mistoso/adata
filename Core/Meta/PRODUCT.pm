package Core::Meta::PRODUCT;
use warnings; use strict;
use Model::Meta;
use Model::Category;
use Data::Dumper;
use Core::Price;
use DB;

sub new {
        my $class = shift;
        my $this  = ();
        $this  = bless { }, $class;
	
	$this->{salemod}  = shift;
	$this->{cat} = Model::Category->load($this->{salemod}->{idCategory});
	$this->{prc} = Core::Price->new();

	my $m = Model::Meta->load('product','what');
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
	
		my $dec = $this->{cat}->dec;
		my $parent = $this->{cat}->parent;#################
		my $parent_dec = $this->{cat}->parent->dec;
		my $meta = $this->{cat}->meta;#################
		my $brands = $this->{salemod}->brands;
	        my $prc = $this->{prc};
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}else{$parent_naOne = $parent->{name};}

		$this->{title} = $this->{position}->{title};

		$this->{title} =~ s/%{category_title}/$meta->{title}/g;
		$this->{title} =~ s/%{category_metaKeywords}/$meta->{metaKeywords}/g;
		$this->{title} =~ s/%{category_metaDescription}/$meta->{metaDescription}/g;

		$this->{title} =~ s/%{category_name}/$this->{cat}->{name}/g;
		$this->{title} =~ s/%{category_name_parent}/$parent->{name}/g;
		$this->{title} =~ s/%{category_one}/$one/g;
		$this->{title} =~ s/%{category_many}/$many/g;
		$this->{title} =~ s/%{category_kogoOne}/$kogoOne/g;
		$this->{title} =~ s/%{category_kogoMany}/$kogoMany/g;
		$this->{title} =~ s/%{category_naOne}/$naOne/g;

		$this->{title} =~ s/%{category_parent_one}/$parent_one/g;
		$this->{title} =~ s/%{category_parent_many}/$parent_many/g;
		$this->{title} =~ s/%{category_parent_kogoOne}/$parent_kogoOne/g;
		$this->{title} =~ s/%{category_parent_kogoMany}/$parent_kogoMany/g;
		$this->{title} =~ s/%{category_parent_naOne}/$parent_naOne/g;

		$this->{title} =~ s/%{name}/$this->{salemod}->{name}/g;
		$this->{title} =~ s/%{desc}/$this->{salemod}->{Description}/g;
		my $price = '.';

		if($this->{salemod}->{price} > 0 && $this->{salemod}->{price} != 9999){$price = ' '.$prc->getByCode($this->{salemod}->{price},"UAH");} 
        
		elsif($this->{salemod}->{baseId} == 1) { 
			my $md_price = $this->{salemod}->price_limit_mods();
			$price = ' - '.$prc->getByCode($md_price->{min_price},"UAH").' ('.$prc->getByCode($md_price->{min_price},"UAH").')';
			if ($md_price->{min_price} < $md_price->{max_price}){
				$price .= ' -  '.$prc->getByCode($md_price->{max_price},"UAH").' ('.$prc->getByCode($md_price->{max_price},"UAH").').' ;}else {$price .= '.';}
		}	        
		$this->{title} =~ s/%{price}/$price/g;
		$this->{title} =~ s/%{brand}/$brands->{name}/g;
		$this->{title} =~ s/%{brandrusName}/$brands->{rusName}/g;
	}
	return $this->{title};
}

sub getDescription {
	my $this = shift;
	unless ($this->{description}) {
		my $dec = $this->{cat}->dec;
		my $parent = $this->{cat}->parent;#################
		my $parent_dec = $this->{cat}->parent->dec;
		my $meta = $this->{cat}->meta;#################
		my $brands = $this->{salemod}->brands;
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}else{$parent_naOne = $parent->{name};}

		$this->{description} = $this->{position}->{description};

		$this->{description} =~ s/%{category_title}/$meta->{title}/g;
		$this->{description} =~ s/%{category_metaKeywords}/$meta->{metaKeywords}/g;
		$this->{description} =~ s/%{category_metaDescription}/$meta->{metaDescription}/g;

		$this->{description} =~ s/%{category_name}/$this->{cat}->{name}/g;
		$this->{description} =~ s/%{category_name_parent}/$parent->{name}/g;
		$this->{description} =~ s/%{category_one}/$one/g;
		$this->{description} =~ s/%{category_many}/$many/g;
		$this->{description} =~ s/%{category_kogoOne}/$kogoOne/g;
		$this->{description} =~ s/%{category_kogoMany}/$kogoMany/g;
		$this->{description} =~ s/%{category_naOne}/$naOne/g;

		$this->{description} =~ s/%{category_parent_one}/$parent_one/g;
		$this->{description} =~ s/%{category_parent_many}/$parent_many/g;
		$this->{description} =~ s/%{category_parent_kogoOne}/$parent_kogoOne/g;
		$this->{description} =~ s/%{category_parent_kogoMany}/$parent_kogoMany/g;
		$this->{description} =~ s/%{category_parent_naOne}/$parent_naOne/g;

		$this->{description} =~ s/%{name}/$this->{salemod}->{name}/g;
		$this->{description} =~ s/%{desc}/$this->{salemod}->{Description}/g;
		my $price = '.';
		if($this->{salemod}->{price} > 0 && $this->{salemod}->{price} != 9999){$price = ' '.$this->{salemod}->{price}.' $.';}

		$this->{description} =~ s/%{price}/$price/g;
		$this->{description} =~ s/%{brand}/$brands->{name}/g;
		$this->{description} =~ s/%{brandrusName}/$brands->{rusName}/g;
	}
	return $this->{description};
}

sub getKeywords {
	my $this = shift;
	unless ($this->{keywords}) {
		my $dec = $this->{cat}->dec;
		my $parent = $this->{cat}->parent;#################
		my $parent_dec = $this->{cat}->parent->dec;
		my $meta = $this->{cat}->meta;#################
		my $brands = $this->{salemod}->brands;
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}else{$parent_naOne = $parent->{name};}

		$this->{keywords} = $this->{position}->{keywords};

		$this->{keywords} =~ s/%{category_title}/$meta->{title}/g;
		$this->{keywords} =~ s/%{category_metaKeywords}/$meta->{metaKeywords}/g;
		$this->{keywords} =~ s/%{category_metaDescription}/$meta->{metaDescription}/g;

		$this->{keywords} =~ s/%{category_name}/$this->{cat}->{name}/g;
		$this->{keywords} =~ s/%{category_name_parent}/$parent->{name}/g;
		$this->{keywords} =~ s/%{category_one}/$one/g;
		$this->{keywords} =~ s/%{category_many}/$many/g;
		$this->{keywords} =~ s/%{category_kogoOne}/$kogoOne/g;
		$this->{keywords} =~ s/%{category_kogoMany}/$kogoMany/g;
		$this->{keywords} =~ s/%{category_naOne}/$naOne/g;

		$this->{keywords} =~ s/%{category_parent_one}/$parent_one/g;
		$this->{keywords} =~ s/%{category_parent_many}/$parent_many/g;
		$this->{keywords} =~ s/%{category_parent_kogoOne}/$parent_kogoOne/g;
		$this->{keywords} =~ s/%{category_parent_kogoMany}/$parent_kogoMany/g;
		$this->{keywords} =~ s/%{category_parent_naOne}/$parent_naOne/g;

		$this->{keywords} =~ s/%{name}/$this->{salemod}->{name}/g;
		$this->{keywords} =~ s/%{desc}/$this->{salemod}->{Description}/g;

		my $price = '.';
		if($this->{salemod}->{price} > 0 && $this->{salemod}->{price} != 9999){$price = ' '.$this->{salemod}->{price}.' $.';}

		$this->{keywords} =~ s/%{price}/$price/g;
		$this->{keywords} =~ s/%{brand}/$brands->{name}/g;
		$this->{keywords} =~ s/%{brandrusName}/$brands->{rusName}/g;
	}
	return $this->{keywords};
}

sub getF_block_left {

	my $this = shift;
	unless ($this->{f_block_left}) {
		my $dec = $this->{cat}->dec;
		my $parent = $this->{cat}->parent;#################
		my $parent_dec = $this->{cat}->parent->dec;
		my $meta = $this->{cat}->meta;#################
		my $brands = $this->{salemod}->brands;
        my $prc = $this->{prc};
        
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}else{$parent_naOne = $parent->{name};}

		$this->{f_block_left} = $this->{position}->{f_block_left};

		$this->{f_block_left} =~ s/%{category_title}/$meta->{title}/g;
		$this->{f_block_left} =~ s/%{category_metaKeywords}/$meta->{metaKeywords}/g;
		$this->{f_block_left} =~ s/%{category_metaDescription}/$meta->{metaDescription}/g;

		$this->{f_block_left} =~ s/%{category_name}/$this->{cat}->{name}/g;
		$this->{f_block_left} =~ s/%{category_name_parent}/$parent->{name}/g;
		$this->{f_block_left} =~ s/%{category_one}/$one/g;
		$this->{f_block_left} =~ s/%{category_many}/$many/g;
		$this->{f_block_left} =~ s/%{category_kogoOne}/$kogoOne/g;
		$this->{f_block_left} =~ s/%{category_kogoMany}/$kogoMany/g;
		$this->{f_block_left} =~ s/%{category_naOne}/$naOne/g;

		$this->{f_block_left} =~ s/%{category_parent_one}/$parent_one/g;
		$this->{f_block_left} =~ s/%{category_parent_many}/$parent_many/g;
		$this->{f_block_left} =~ s/%{category_parent_kogoOne}/$parent_kogoOne/g;
		$this->{f_block_left} =~ s/%{category_parent_kogoMany}/$parent_kogoMany/g;
		$this->{f_block_left} =~ s/%{category_parent_naOne}/$parent_naOne/g;

		$this->{f_block_left} =~ s/%{name}/$this->{salemod}->{name}/g;
		$this->{f_block_left} =~ s/%{desc}/$this->{salemod}->{Description}/g;
		my $price = '.';
		if	($this->{salemod}->{price} > 0 && $this->{salemod}->{price} != 9999){$price = ' '.$prc->getByCode($this->{salemod}->{price},"UAH");} 
        	elsif($this->{salemod}->{baseId} == 1) { 
			my $md_price = $this->{salemod}->price_limit_mods();
			$price = ' - '.$prc->getByCode($md_price->{min_price},"UAH").' ('.$prc->getByCode($md_price->{min_price},"UAH").')';
			if ($md_price->{min_price} < $md_price->{max_price}){
				$price .= ' -  '.$prc->getByCode($md_price->{max_price},"UAH").' ('.$prc->getByCode($md_price->{max_price},"UAH").').' ;}else {$price .= '.';}
		}	        
		$this->{f_block_left} =~ s/%{price}/$price/g;
		$this->{f_block_left} =~ s/%{brand}/$brands->{name}/g;
		$this->{f_block_left} =~ s/%{brandrusName}/$brands->{rusName}/g;
        
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
		my $dec = $this->{cat}->dec;
		my $parent = $this->{cat}->parent;#################
		my $parent_dec = $this->{cat}->parent->dec;
		my $meta = $this->{cat}->meta;#################
		my $brands = $this->{salemod}->brands;
        my $prc = $this->{prc};
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}else{$parent_naOne = $parent->{name};}

		$this->{s_block} = $this->{position}->{s_block};

		$this->{s_block} =~ s/%{category_title}/$meta->{title}/g;
		$this->{s_block} =~ s/%{category_metaKeywords}/$meta->{metaKeywords}/g;
		$this->{s_block} =~ s/%{category_metaDescription}/$meta->{metaDescription}/g;

		$this->{s_block} =~ s/%{category_name}/$this->{cat}->{name}/g;
		$this->{s_block} =~ s/%{category_name_parent}/$parent->{name}/g;
		$this->{s_block} =~ s/%{category_one}/$one/g;
		$this->{s_block} =~ s/%{category_many}/$many/g;
		$this->{s_block} =~ s/%{category_kogoOne}/$kogoOne/g;
		$this->{s_block} =~ s/%{category_kogoMany}/$kogoMany/g;
		$this->{s_block} =~ s/%{category_naOne}/$naOne/g;

		$this->{s_block} =~ s/%{category_parent_one}/$parent_one/g;
		$this->{s_block} =~ s/%{category_parent_many}/$parent_many/g;
		$this->{s_block} =~ s/%{category_parent_kogoOne}/$parent_kogoOne/g;
		$this->{s_block} =~ s/%{category_parent_kogoMany}/$parent_kogoMany/g;
		$this->{s_block} =~ s/%{category_parent_naOne}/$parent_naOne/g;

		$this->{s_block} =~ s/%{name}/$this->{salemod}->{name}/g;
		$this->{s_block} =~ s/%{desc}/$this->{salemod}->{Description}/g;
		my $price = '.';
		if	($this->{salemod}->{price} > 0 && $this->{salemod}->{price} != 9999){$price = ' '.$prc->getByCode($this->{salemod}->{price},"UAH");} 
        	elsif($this->{salemod}->{baseId} == 1) { 
			my $md_price = $this->{salemod}->price_limit_mods();
			$price = ' - '.$prc->getByCode($md_price->{min_price},"UAH").' ('.$prc->getByCode($md_price->{min_price},"UAH").')';
			if ($md_price->{min_price} < $md_price->{max_price}){
				$price .= ' - '.$prc->getByCode($md_price->{max_price},"UAH").' ('.$prc->getByCode($md_price->{max_price},"UAH").').' ;}else {$price .= '.';}
		}	        
		$this->{s_block} =~ s/%{price}/$price/g;
		$this->{s_block} =~ s/%{brand}/$brands->{name}/g;
		$this->{s_block} =~ s/%{brandrusName}/$brands->{rusName}/g;
        
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
		my $dec = $this->{cat}->dec;
		my $parent = $this->{cat}->parent;#################
		my $parent_dec = $this->{cat}->parent->dec;
		my $meta = $this->{cat}->meta;#################
		my $brands = $this->{salemod}->brands;
        my $prc = $this->{prc};
###########
		my $one;
		if($dec->{one}){$one = $dec->{one};}else{$one = $this->{cat}->{name};}
##########
		my $many;
		if($dec->{many}){$many = $dec->{many};}else{$many = $this->{cat}->{name};}
##########
		my $kogoOne;
		if($dec->{kogoOne}){$kogoOne = $dec->{kogoOne};}else{$kogoOne = $this->{cat}->{name};}
##########
    		my $kogoMany;
    		if($dec->{kogoMany}){$kogoMany = $dec->{kogoMany};}else{$kogoOne = $this->{cat}->{name};}
##########
		my $naOne;
		if($dec->{naOne}){$naOne = $dec->{naOne};}else{$naOne = $this->{cat}->{name};}
##########
		my $parent_one;
		if($parent_dec->{one}){$parent_one = $parent_dec->{one};}else{$parent_one = $parent->{name};}
##########
		my $parent_many;
		if($parent_dec->{many}){$parent_many = $parent_dec->{many};}else{$parent_many = $parent->{name};}
##########
		my $parent_kogoOne;
		if($parent_dec->{kogoOne}){$parent_kogoOne = $parent_dec->{kogoOne};}else{$parent_kogoOne = $parent->{name};}
##########
    		my $parent_kogoMany;
    		if($parent_dec->{kogoMany}){$parent_kogoMany = $parent_dec->{kogoMany};}else{$parent_kogoOne = $parent->{name};}
##########
		my $parent_naOne;
		if($parent_dec->{naOne}){$parent_naOne = $parent_dec->{naOne};}else{$parent_naOne = $parent->{name};}

		$this->{f_block_right} = $this->{position}->{f_block_right};

		$this->{f_block_right} =~ s/%{category_title}/$meta->{title}/g;
		$this->{f_block_right} =~ s/%{category_metaKeywords}/$meta->{metaKeywords}/g;
		$this->{f_block_right} =~ s/%{category_metaDescription}/$meta->{metaDescription}/g;

		$this->{f_block_right} =~ s/%{category_name}/$this->{cat}->{name}/g;
		$this->{f_block_right} =~ s/%{category_name_parent}/$parent->{name}/g;
		$this->{f_block_right} =~ s/%{category_one}/$one/g;
		$this->{f_block_right} =~ s/%{category_many}/$many/g;
		$this->{f_block_right} =~ s/%{category_kogoOne}/$kogoOne/g;
		$this->{f_block_right} =~ s/%{category_kogoMany}/$kogoMany/g;
		$this->{f_block_right} =~ s/%{category_naOne}/$naOne/g;

		$this->{f_block_right} =~ s/%{category_parent_one}/$parent_one/g;
		$this->{f_block_right} =~ s/%{category_parent_many}/$parent_many/g;
		$this->{f_block_right} =~ s/%{category_parent_kogoOne}/$parent_kogoOne/g;
		$this->{f_block_right} =~ s/%{category_parent_kogoMany}/$parent_kogoMany/g;
		$this->{f_block_right} =~ s/%{category_parent_naOne}/$parent_naOne/g;

		$this->{f_block_right} =~ s/%{name}/$this->{salemod}->{name}/g;
		$this->{f_block_right} =~ s/%{desc}/$this->{salemod}->{Description}/g;
		my $price = '.';
		if	($this->{salemod}->{price} > 0 && $this->{salemod}->{price} != 9999){$price = ' '.$prc->getByCode($this->{salemod}->{price},"UAH");} 
        	elsif($this->{salemod}->{baseId} == 1) { 
			my $md_price = $this->{salemod}->price_limit_mods();
			$price = ' - '.$prc->getByCode($md_price->{min_price},"UAH").' ('.$prc->getByCode($md_price->{min_price},"UAH").')';
			if ($md_price->{min_price} < $md_price->{max_price}){
				$price .= ' - '.$prc->getByCode($md_price->{max_price},"UAH").' ('.$prc->getByCode($md_price->{max_price},"UAH").').' ;}else {$price .= '.';}
		}	        
		$this->{f_block_right} =~ s/%{price}/$price/g;
		$this->{f_block_right} =~ s/%{brand}/$brands->{name}/g;
		$this->{f_block_right} =~ s/%{brandrusName}/$brands->{rusName}/g;

        if (($this->{f_block_right} eq ' ') || ($this->{f_block_right} eq '')){
            my $sth = $db->prepare('SELECT right_block from default_footer_block');
            $sth->execute();
            $this->{f_block_right} = $sth->fetchrow_array();
        }
	}
	return $this->{f_block_right};
}

1;
