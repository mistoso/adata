package Core::Meta::OTZIVPRODUCT;
use warnings; use strict;
use Model::Meta;
use Model::Category;

sub new {
        my $class = shift;
        my $this  = ();
        $this  = bless { }, $class;
	
	$this->{salemod}  = shift;
	$this->{cat} = Model::Category->load($this->{salemod}->{idCategory});
	my $m = Model::Meta->load('product','what');
	if ($m) {
		$this->{position}->{title} = $m->{title};
		$this->{position}->{description} = $m->{description};
		$this->{position}->{keywords} = $m->{keywords};
	}
	else {
		$this->{position}->{title} = '';
		$this->{position}->{description} = '';
		$this->{position}->{keywords} = '';
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
		$this->{title} =~ s/%{price}/$this->{salemod}->{price}/g;
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

		$this->{description} = $this->{position}->{title};

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
		$this->{description} =~ s/%{price}/$this->{salemod}->{price}/g;
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

		$this->{keywords} = $this->{position}->{title};

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
		$this->{keywords} =~ s/%{price}/$this->{salemod}->{price}/g;
		$this->{keywords} =~ s/%{brand}/$brands->{name}/g;
		$this->{keywords} =~ s/%{brandrusName}/$brands->{rusName}/g;
	}
	return $this->{keywords};
}
1;
