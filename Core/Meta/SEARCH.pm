package Core::Meta::SEARCH;
use warnings; use strict;
use Model::Meta;
use DB;

sub new {
    my $class = shift;
    my $this  = ();
    $this  = bless { }, $class;

    $this->{name}  = shift;
    my $m = Model::Meta->load('search','what');

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
        $this->{title} = $this->{position}->{title}; 
		$this->{title} =~ s/%{name}/$this->{name}/g;
	}

	return $this->{title};
}

sub getDescription {
	my $this = shift;

	unless ($this->{description}) {
        $this->{descriprion} = $this->{position}->{descriprion}; 
		$this->{description} =~ s/%{name}/$this->{name}/g;
	}

	return $this->{description};
}

sub getKeywords {
	my $this = shift;

	unless ($this->{keywords}) {
        $this->{keywords} = $this->{position}->{keywords}; 
		$this->{keywords} =~ s/%{name}/$this->{name}/g;
	}

	return $this->{keywords};
}

sub getF_block_left {
    my $this = shift;

    unless ($this->{f_block_left} ) {
        $this->{f_block_left} = $this->{position}->{f_block_left};
        $this->{f_block_left} =~ s/%{name}/$this->{name}/g;
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

    unless ($this->{s_block} ) {
        $this->{s_block} = $this->{position}->{s_block};
        $this->{s_block} =~ s/%{name}/$this->{name}/g;
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

    unless ($this->{f_block_right} ) {
        $this->{f_block_right} = $this->{position}->{f_block_right};
        $this->{f_block_right} =~ s/%{name}/$this->{name}/g;
        if (($this->{f_block_right} eq ' ') || ($this->{f_block_right} eq '')){
            my $sth = $db->prepare('SELECT right_block from default_footer_block');
            $sth->execute();
            $this->{f_block_right} = $sth->fetchrow_array();
        }       
    }
    return $this->{f_block_right};
}
1;
