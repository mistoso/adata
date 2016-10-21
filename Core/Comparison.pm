package Core::Comparison;
use Core::User;
use Data::Dumper;
use Model::SaleMod;
use Core::User;
use DB;

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self;
}

sub del_prod_from_compare(){
    my $self = shift;
    my $idSaleMod = shift;


    my @buf_old;

    my $user = Core::User->current();
    my $comprod = $user->session->get('comparison');

    @buf_old = @{$comprod->{'prod'}};
    undef @{$comprod->{'prod'}};

    foreach (@buf_old){
        push @{$comprod->{'prod'}}, $_ if $idSaleMod ne $_;
    }

    $user->session->set('comparison' => $comprod);
    $user->session->save();
}

sub clean(){
    my $self = shift;
    my $user = Core::User->current();
    my $comprod = $user->session->get('comparison');
    undef @{$comprod->{'prod'}};
    return 1;
}
sub add_prod_to_compare(){
    my $self = shift;
    my $id = shift;
    warn $id;

    my $user = Core::User->current();

    my $comprod = $user->session->get('comparison');

    my $cat = $comprod->{'cat'};

#   &check_prod_before_add($idSaleMod);
#   if (&check_prod_feature($idSaleMod)){

        my $SaleMod = Model::SaleMod->load($id) or print "nnnneeeeeeeeeeeeeeeeeeeeeeeeettttttttttttt";
        warn Dumper($SaleMod);

        if ($cat eq ''){
                $cat = $SaleMod->{idCategory};
                push @{$comprod->{'prod'}},$SaleMod->{id};
        }

        elsif ($cat eq $SaleMod->{idCategory}){
                @buf_old = @{$comprod->{'prod'}};
                my $isin = 0;
                foreach (@buf_old){
                        $isin = 1 if $_ eq $SaleMod->{id};
                }

            push @{$comprod->{'prod'}},$SaleMod->{id} unless $isin;
        }
        else{
                $cat = $SaleMod->{idCategory};
                undef @{$comprod->{'prod'}};
                push @{$comprod->{'prod'}},$SaleMod->{id};
        }
        $comprod->{'cat'} = $cat;
        $user->session->set('comparison' => $comprod);
        $user->session->save();
#       }
}

sub check_prod_before_add(){
    my $idSaleMod = shift;
    return 1;
}

sub check_prod_feature(){
    my $idSaleMod = shift;
    
    my $sth = $db->prepare("select count(*) from features where idSalemod = ? and value <> '' ");
    $sth->execute($idSaleMod);
    my ($count) = $sth->fetchrow_array();
    
    return 1 if $count > '0';
    return 0;
}

sub get_category_feature(){
    my $self = shift;
    my $idCategory = shift;
    my @buf = ();

    my $sth = $db->prepare("select id, name from feature_groups where idCategory = ? and name <> '' and idParent = 0 and public order by orderby");
    $sth->execute($idCategory);
    my @features = ();
    while (my $feature_group = $sth->fetchrow_hashref()) {
        my @tmp = ();
        my $csth = $db->prepare("select id,type,name from feature_groups where idCategory = ? and idParent = ? order by orderby");
        $csth->execute($idCategory,$feature_group->{id});
        while(my $item = $csth->fetchrow_hashref()) {
            push (@tmp,$item);
        }
        if (scalar(@tmp) > 0) {
            $feature_group->{childs} = \@tmp;
            push (@features,$feature_group);
        }
    }
    return \@features;
}

sub compare(){
    my $comprod = $s->get('comparison');
    my @buf;

    foreach (@{$comprod->{'prod'}}){
        my $SaleMod = Model::SaleMod->load($_);# or return &main_index();
        push @buf,$SaleMod;
    }

    return \@buf;
}
1;
