package Core::Find;

use Sphinx::Search;
use POSIX;
use Data::Dumper;
use Cfg;
use Core::DB;
use Clean;
use strict;

sub new(){
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub search_brand_name(){
    my $self = shift;
    my $total_found = 0;
    my $frase = $self->{'bfrase'};
    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});
    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });
        $sp->SetMatchMode( SPH_MATCH_ALL );
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        $frase =~ s/,//g;
        $sp->SetLimits(0,5);
        my $result = $sp->Query( '*'.$frase.'*' ,$cfg->{sphinx}->{bname_index});
        #$total_found = $result->{total};
        #if ($total_found eq '0') {
        #    $result = $sp->Query('@name *'.$frase.'*',$cfg->{sphinx}->{bname_index});
        #}
        $sp->Close();
        foreach (@{$result->{matches}}) {
            push  @{$self->{'brands'}},$_->{'doc'};
        }
    }
}

sub search_category_name(){
    my $self = shift;
    my $frase = $self->{'cfrase'};
    my $total_found = 0;
    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});
    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });
        $sp->SetMatchMode( SPH_MATCH_ALL );
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        $frase =~ s/,//g;
        #$frase = $sp->EscapeString($frase);
        $sp->SetLimits(0,20);
        my $result = $sp->Query( '*'.$frase.'*' ,$cfg->{sphinx}->{cname_index});
        #$total_found = $result->{total};
        #if ($total_found eq '0') {
        #    $result = $sp->Query('*'.$frase.'*',$cfg->{sphinx}->{cname_index});
        #}
        $sp->Close();
        foreach (@{$result->{'matches'}}) {
            push @{$self->{'cats'}},$_->{'doc'};
        }
    }
}

sub search_salemod_name(){
    my $self = shift;
    my $frase = $self->{'frase'};
    my $total_found = 0;
    my $query = '';
    my $result;
    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});
    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        $frase =~ s/,//g;
        if ($self->{'isPublic'} == 1){
            my @mas = [1];    
            $sp->SetFilter("isPublic",@mas);
        }
        my $wcont = scalar(split(/ /,$frase));
        $query = $frase;
        $sp->SetLimits(0,1000);
        if ($wcont = '1'){
            $sp->SetMatchMode( SPH_MATCH_ALL );
            $result = $sp->Query($query,$cfg->{sphinx}->{name_index});
            $total_found = $result->{total};
            if ($total_found eq '0') {
                $result = $sp->Query('*'.$query.'*',$cfg->{sphinx}->{name_index});
            }
        }else{
            $sp->SetMatchMode( SPH_MATCH_EXTENDED );
            if ($wcont < 7){$query = '@name "'.$frase.'"/'.ceil($wcont / 2);}
            elsif ($wcont >= 7){$query = '@name "'.$frase.'"/3';}

            $result = $sp->Query( $query ,$cfg->{sphinx}->{name_index});
            $total_found = $result->{total};

            if ($total_found eq '0' ) {
                $sp->SetMatchMode( SPH_MATCH_ANY );
                $result = $sp->Query('*'.$frase.'*',$cfg->{sphinx}->{name_index});
            }
        }
        $sp->Close();
        foreach (@{$result->{matches}}) {
            push @{$self->{'ids'}},$_->{doc};
        }
    }
}
sub search_salemod_pname(){
    my $self = shift;
    my $frase = $self->{'frase'};
    my $total_found = 0;
    my $query = '';
    my $result;
    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});
    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });
        $sp->SetMatchMode( SPH_MATCH_ALL );
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        $frase =~ s/,//g;
        #$frase = $sp->EscapeString($frase);
        #$query = $frase;
	$frase =~ s/\s/* */g;
        $sp->SetLimits(0,100);
        $result = $sp->Query( "*$frase*",$cfg->{sphinx}->{pname_index});
        $sp->Close();
        foreach (@{$result->{matches}}) {
            push @{$self->{'ids'}},$_->{doc};
        }
    }
}

sub search_result_in_mysql(){
    my $self = shift;

    my $tmp = "search_".time();
    $tmp .= "_p" if $self->{'apr_table'} eq '1';
    $self->{'tname'} = $tmp;
    my $ids;
    foreach (@{$self->{'ids'}}) {
        $ids .= $_.",";
    }
    chomp($ids);
    #return undef if scalar($ids) = 0;
    my $temporary;
    $temporary = 'temporary';
    my $sth = $db->prepare("create $temporary table $tmp (id int(6) unsigned NOT NULL ,PRIMARY KEY (id));");
    $sth->execute();

    open ("FILE",">/tmp/$tmp.txt");

    print FILE $ids;
    close FILE;
    
    my $sth = $db->prepare("LOAD DATA LOCAL INFILE '/tmp/$tmp.txt' INTO TABLE $tmp CHARACTER SET 'utf8' LINES TERMINATED BY ',';");
    $sth->execute();
    unlink("/tmp/$tmp.txt"); 
    
} 

sub search_result_categories(){
    my $self = shift;
    my @categores;
    my $tmp = $self->{'tname'};
    my $sth = $db->prepare("select c.id,c.name,c.categoryOrder,count(*) as cnt from salemods as s inner join $tmp as tmp on tmp.id = s.id inner join category as c on s.idCategory = c.id where not s.deleted and not c.deleted group by s.idCategory order by categoryOrder");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref()){
        push @categores,$item;
    }
    return \@categores;
}

sub search_result_brands(){
    my $self = shift;
    my @brands;
    my $tmp = $self->{'tname'};
    my $sth = $db->prepare("select b.id,b.name,count(*) as cnt from salemods as s inner join $tmp as tmp on tmp.id = s.id inner join brands as b on s.idBrand = b.id where not s.deleted and not b.deleted group by b.id order by cnt desc");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref()){
        push @brands,$item;
    }
    return \@brands;
}

sub search_apr(){
    my $self = shift;
    my $section = shift;
    my $limit = shift || '10';
    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});
    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });

        $sp->SetMatchMode( SPH_MATCH_ANY );
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        if ($section > 0) {
            push my @s,$section;
            $sp->SetFilter("idc",\@s);
        }
        $sp->SetLimits(0,$limit);
        my $result = $sp->Query( '*'.$self->{'frase'}.'*',$cfg->{sphinx}->{aname_index});

        $sp->Close();
        foreach (@{$result->{matches}}) {
            push @{$self->{'ids'}},$_->{doc};
        }
    }
    $self->{'apr_table'} = 1;
} 

sub search_result_sections(){
    my $self = shift;
    my @apr;
    my $tmp = $self->{'tname'};
    my $sth = $db->prepare("select s.name,count(*) as cnt,p.idCategory as cat,s.alias from apr_sections as s inner join apr_pages as p on s.id = p.idCategory inner join $tmp as tmp on p.id = tmp.id group by p.idCategory");
    $sth->execute();
    while (my $item = $sth->fetchrow_hashref()){
        my $sthp = $db->prepare("select p.name,p.alias,p.Description from apr_pages as p inner join $tmp as tmp on p.id = tmp.id where p.idCategory = ?");
        $sthp->execute($item->{'cat'});
        while (my $itemp = $sthp->fetchrow_hashref()){
            push @{$item->{'buf'}},$itemp;
        }
        push @apr,$item;
    }
    return \@apr;
}

1;
