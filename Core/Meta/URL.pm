package Core::Meta::URL;
use Model::Meta::Url;
use DB;
sub new {
        my $class = shift;
        my $this  = ();
        $this  = bless { }, $class;
	
	$this->{req} = shift;
	
	return $this;
}

sub init {
	my $this = shift;

	unless ($this->{entry}) {
	    $this->{entry} = Model::Meta::Url->load($this->{req},'url');
	    unless ($this->{entry}) { 
		$this->{entry}->{title} = '';
		$this->{entry}->{description} = '';
		$this->{entry}->{keywords} = '';
        	$this->{entry}->{f_block_left} = '';
        	$this->{entry}->{s_block} = '';
        	$this->{entry}->{f_block_right} = '';
	    }
	}
	return $this->{entry};
}

sub getTitle {
	my $this = shift;
	$this->init();
	return $this->{entry}->{title};
}

sub getDescription {
	my $this = shift;
	$this->init();
	return $this->{entry}->{description};
}

sub getKeywords {
	my $this = shift;

	$this->init();
	return $this->{entry}->{keywords};
}           
sub getF_block_left {
    my $this = shift;
    $this->init();
    if (($this->{entry}->{f_block_left} eq ' ') || ($this->{entry}->{f_block_left} eq '')){
        my $sth = $db->prepare('SELECT left_block from default_footer_block');
        $sth->execute();
        $this->{entry}->{f_block_left} = $sth->fetchrow_array();
    }       
    return $this->{entry}->{f_block_left};
}

sub getS_block {
    my $this = shift;
	$this->init();

    if (($this->{entry}->{s_block} eq ' ') || ($this->{entry}->{s_block} eq '')){
        my $sth = $db->prepare('SELECT centr_block from default_footer_block');
        $sth->execute();
        $this->{entry}->{s_block} = $sth->fetchrow_array();
    }       
    return $this->{entry}->{s_block};
}

sub getF_block_right {
    my $this = shift;
    $this->init();
    if (($this->{entry}->{f_block_right} eq ' ') || ($this->{entry}->{f_block_right} eq '')){
	my $sth = $db->prepare('SELECT right_block from default_footer_block');
        $sth->execute();
        $this->{entry}->{f_block_right} = $sth->fetchrow_array();
    }
    return $this->{entry}->{f_block_right};
}
1;
