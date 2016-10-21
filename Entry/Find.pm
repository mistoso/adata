package Entry::Find;
#use strict;
#use warnings;
use locale;
use POSIX qw(locale_h);
setlocale(LC_CTYPE,"ru_UA.UTF-8");
use Apache2::Const qw/OK NOT_FOUND REDIRECT SERVER_ERROR FORBIDDEN M_GET/;
use Apache2::SubRequest;
use Apache2::RequestRec;
use Sphinx::Search;
use Cfg;
use Core::DB;
use Tools;
use Logger;
use Core::Pager;
use Core::Template qw/get_template/;
use Cfg;
use Clean;
use Core::User;
use Core::Session;
use Model::SaleMod;
use Encode;
use Core::Meta;
use Data::Dumper;
use Core::Find;
use Model::Category;
use Model::Brand;

our $r;
our $s;
our $user;
our $args;
my $ALIAS = " \\_ \\w \\d \\- \\+ \\( \\) \\: \\, \\.";


sub handler(){
	our $r = shift;
	my $req = $r->uri();
	$r->content_type('text/html');
	our $args = &Tools::get_request_params($r);
	our $params_string = '';



	$s = Core::Session->instance(1); 
	our $user = Core::User->current();
#	Encode::from_to($req,"utf8","cp1251");
	Core::Meta->instance(1,$req);
	my %content = (
		"\\/find\\/([$ALIAS]+)\\.htm" => *search_sphinx{CODE},
		"\\/find\\/([$ALIAS]+)\\/(\\d+)\\.html" => *search_sphinx_in_cat{CODE},
		"\\/find\\/([$ALIAS]+)\\/([$ALIAS]+)\\.htm" => *search_sphinx_in_brand{CODE},
	);
	map { $args->{$_} = Clean->all($args->{$_}) } keys %{$args};
	foreach my $reg (keys %content){
		if (my @args = ($req =~ /^$reg$/)){
			return &{$content{$reg}}(@args);
			return $r if $r;
		}
	}
	### budlo fixxx

	    $req =~ s|/find/||;
	    $req =~ s|\.html||;
	    $req =~ s|\.htm.*$||;
	    $req =~ s|\/| |;
	    search_sphinx($req);

	#print Dumper($req);
	#print Dumper($params_string);
	#return NOT_FOUND;
}

sub search_sphinx_in_cat {
	my $string = shift;
	my $category = Model::Category->load(shift);
	$args->{'idCategory'} = $category->{'id'};
	$args->{'category'} = $category;
	print 'c';
	&search_sphinx($string);
}

sub search_sphinx_in_brand {
	my $string = shift;
	my $brand = Model::Brand->load(shift,'alias');
	$args->{'idBrand'} = $brand->{'id'};
	$args->{'brand'} = $brand;
	print 'b';
	&search_sphinx($string);
}

sub search_sphinx {
    my $string = Clean->all(shift);
    Core::Meta->instance->change($string,'search');

    SEARCHSTART:
    my @buf= ();
    my $error = '';
    my $total_found = 0;
    my ($cat,$brand);

    $string =~ s/\-/ /g;
   ###################### new 

    my $srch = Core::Find->new();
    $srch->{'frase'} = $string;
    $srch->{'isPublic'} = 1;

    my $pager = Core::Pager->new($args->{page},$args->{onpage});

    my $sp = Sphinx::Search->new();
    $sp->SetServer($cfg->{sphinx}->{host}, $cfg->{sphinx}->{port});

    if($sp->Open()) {
        $sp->SetEncoders( sub { shift }, sub { shift });
        $sp->SetMatchMode( SPH_MATCH_ALL );
        $sp->SetSortMode( SPH_SORT_RELEVANCE );
        my @mas = [1];

        $sp->SetFieldWeights($cfg->{sphinx}->{weight});
        $sp->SetLimits(0,1000);
        $sp->SetFilter("ispublic",@mas);
	if ($args->{'idCategory'} > 0) {
            	push my @cas,$args->{'idCategory'};
            	$sp->SetFilter("idcategory",\@cas);
        }
        if ($args->{'idBrand'} > 0) {
            push my @bas,$args->{'idBrand'};
            $sp->SetFilter("idbrand",\@bas);
        }
	my $sstring = $string;
	$sstring =~ s/\s/* */g;
        my $result = $sp->Query("*$sstring*",$cfg->{sphinx}->{name_index});

        #my $result = $sp->Query("$string",$cfg->{sphinx}->{name_index});
      
        if ($result->{error} eq '') {
            $total_found = $result->{total};
            if ($total_found eq '0' and scalar(split(//,$string)) > 2) {
                $sp->SetMatchMode( SPH_MATCH_ALL );
                $result = $sp->Query("*$string*",$cfg->{sphinx}->{name_index});
                $total_found = $result->{total};
            }
            $pager->setMax($total_found);
            my $i = 0;
            foreach (@{$result->{matches}}) {$i+=1;
            	my $mod;
            	if (($i >= $pager->getOffset) && ($i <= $pager->getLimit + $pager->getOffset)){
            		$mod = Model::SaleMod->load($_->{doc});
            	}
            	$mod->{'search'} = $_;
               push @buf,$mod;
            }
            
            #print Dumper(@buf);                            
        }
        else {
            $error = 1;
        }
          $sp->Close();   
    }
    else {
        $error = 1;
    }
    if ($args->{page} =~ /^\d+$/ and $args->{page} > $pager->getPagesCount()) {
        $args->{page} = $pager->getPagesCount();
        goto SEARCHSTART;
    }

	my @buff = reverse(@buf);    
	get_template(
       'frontoffice/templates/search' => $r,
        string  => $string,
        list    => \@buf,
        totalfound  => $total_found,
        pager   => $pager,
	);
	return 'OK';
}
############ new
sub new_search_sphinx {
    my $string = shift;

    #Core::Meta->instance->change($string,'search');

    my @buf= ();
    my $error = '';
    my $total_found = 0;

    my $pager = Core::Pager->new($args->{page},$args->{onpage});
    my $srch = Core::Find->new();
    $srch->{'frase'} = $args->{'frase'};
    $srch->{'bfrase'} = $args->{'frase'};
    $srch->{'cfrase'} = $args->{'frase'};

    $srch->search_brand_name();
    $srch->search_category_name();
    $srch->search_salemod_name();
    $srch->search_result_in_mysql();

    my @categories = $srch->search_result_categories();
    my @brands = $srch->search_result_brands();

    my $srch = Core::Find->new();
    $srch->{'frase'} = $args->{'frase'};
    $srch->search_apr();
    $srch->search_result_in_mysql();
    my @apr = $srch->search_result_sections();


    get_template(
        'backoffice/templates/search' => $r,
        'cats'  =>  @categories,
        'brands'=>  @brands,
        'aprs'  =>  @apr,
        'frase' =>  $args->{'frase'},
     );

     return 'OK';
}
1;
