#!/usr/bin/perl
package CmpParser;
### use warnings; use strict;
use FindBin; use lib "$FindBin::Bin/../lib"; 
use HTML::TreeBuilder; use XML::XPath; use XML::XPath::XMLParser;
use LWP::UserAgent; use Encode; use Core::File;

sub new() { 
    my ( $class ) = shift; 
    my ( $self  ) = {
        link        => shift || 0, 
        enc	    => shift || 'utf8',
        paged       => shift || 0,
        debug       => 1,
        debug_page  => 0
    };
    bless ( $self, $class ); 
    return $self; 
}
sub get_prods_list() {
    my $self = shift; my $pc = 0; my @b  = ( );

    for( my $i = $self->{paged}; 1; $i++ ) 
    {
	my $url = sprintf( $self->{link}, $i );
        my $tree = HTML::TreeBuilder->new_from_content( $self->req( $url ) ); #print " \n-\n ".sprintf( $self->{link}, $i )." \n-\n " if ( $self->{debug_page} );

	eval { $tree->as_XML(); }; 

	if( $@ ){ 
	    Core::File->file_log( "/tmp/list_hotline_parser_bad_urls.log", $url.$@."\n" ); next; 
	}

        my $xp = XML::XPath->new( xml => $tree->as_XML() ); 
	my $h1 = $xp->find('//h1')->string_value; 
	$pc = 0;

	foreach my $node ($xp->find('//ul[@class="catalog"]/li')->get_nodelist)
        {
	    $xp = XML::XPath->new(context => $node); $pc++;
            my $name        = $xp->find('//h3')->string_value;                           	#print "$name\n";
            my $href        = $xp->find('//h3/a/@href')->string_value;                   	#print "$href\n";
            my $img         = $xp->find('//div/@hltip')->string_value;                   	#print "$img\n";
            my $price       = $xp->find('//span[@class="orng"]')->string_value || 0;     	#print "$price\n";
            my ( $dsc, $a ) = split( 'Сравнить', $xp->find('//p[1]')->string_value );   #print "$desc\n--\n";
	    binmode STDOUT, ':utf8'; # print "$pc|$h1|$name|$href|$img|$price|$dsc\n" if ( $self->{debug} );
	    my $row = "$pc|$h1|$name|$href|$img|$price|$dsc|$url\n"; #if ( $self->{debug} );
	    Core::File->file_log( "/var/www/search.stylus.com.ua/var/ext/list_products_hotline.csv", $row ); 
#           push @b, { name => $name, href => $href, img => $img, price => $price, desc => $dsc };
        }

        last if $pc == 0; # exit;
    }
    return \@b;
}

sub req(){
    my ( $self, $url ) = @_;
    my $ua = LWP::UserAgent->new(); 

    $ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.9.1.7) Opera/3.5.7'); 



    my $ra = $ua->get( $url );
    if ( $ra->is_success ) { 
        my $c = $ra->content();
	##############################################################
        #Encode::from_to($c, 'cp1251', 'utf-8');

        $c =~ s/[\n+|\t+|\r+]/ /g; 
	$c =~ s/\s+/ /g;
	$c =~ s/\s+</</g;
	$c =~ m/<body class="fon">(.+)<\/body>/g;
	$c = $1;
	## for beautify html
#        $c =~ s/</\n</g; $c =~ s/\n<\//<\//g;
	$c =~ s/<(img|input)[\s\S]*?>//g;
	$c =~ s/<(script|noscript|title)[\s\S]*?>[\s\S]*?<\/(title|script|noscript)>//g;
	$c =~ s/<div class="more">[\s\S]*?<\/div><\/div>//g;
	##############################################################
	#print $c;
        return $c;

    } else { 
        print "erroooeerrr\n".print $ra->status_line;
        return 0;
    } 
}

my @lot_urls = (
    '/deti/razvivayuschie-igrushki/',
    '/deti/interaktivnye-igrushki/',
    '/deti/razvivayuschie-kovriki/',
    '/deti/muzykalnye-karuseli-mobili/',
    '/deti/pogremushki-gryzunki-price/',
    '/deti/detskie-konstruktory/',
    '/deti/nastolnye-igry/',
    '/deti/pazly/',
    '/deti/detskie-mozaiki/',
    '/deti/igrovye-nabory/',
    '/deti/nabory-dlya-detskogo-tvorchestva/',
    '/deti/detskie-muzykalnye-instrumenty/',
    '/deti/detskie-knigi-price/',
    '/deti/igrushki-dlya-devochek/',
    '/deti/myagkie-igrushki/',
    '/deti/igrovye-figurki-price/',
    '/deti/igrushki-dlya-malchikov/',
    '/deti/avtomodeli/',
    '/deti/radioupravlyaemye-modeli/',
    '/deti/zapchasti-k-radioupravlyaemym-modelyam-price/',
    '/deti/aksessuary-dlya-sbornyh-modelej-price/',
    '/deti/transformery/',
    '/deti/plyazhnye-naduvnye-igrushki-i-bassejny/',
    '/deti/igrovye-domiki-palatki/',
    '/deti/detskie-krovatki-i-manezhi/',
    '/deti/aksessuary-dlya-detskih-krovatok-price/',
    '/deti/pelenalnye-komody-i-stoliki/',
    '/deti/detskie-kresla-kachalki/',
    '/deti/stulchiki-dlya-kormleniya/',
    '/dom/matrasy/',
    '/deti/komplekty-detskoj-mebeli-price/',
    '/deti/detskie-shkafy-komody-price/',
    '/deti/detskie-stoly-i-stulya/',
    '/deti/detskie-pismennye-stoly-i-party/',
    '/deti/detskie-krovati/',
    '/deti/dvuhyarusnye-krovati/',
    '/dom/divany/',
    '/sport/sportivnye-kompleksy/',
    '/deti/igrovye-ploschadki-price/',
    '/deti/detskie-kacheli-price/',
    '/deti/gorki-price/',
    '/deti/yaschiki-dlya-igrushek-price/',
    '/deti/detskaya-mebel-ostalnoe-price/',
    '/dom/podushki/',
    '/dom/pledy/',
    '/dom/pokryvala/',
    '/dom/komplekty-postelnogo-belya/',
    '/dom/nabory-dlya-detskoj-krovatki-kolyaski/',
    '/dom/kovry/',
    '/dom/polotenca/',
    '/dom/halaty/',
    '/deti/detskie-kolyaski/',
    '/deti/aksessuary-dlya-kolyasok-price/',
    '/deti/lyulki-dlya-kolyasok-price/',
    '/deti/avtokresla/',
    '/deti/aksessuary-dlya-avtokresel-price/',
    '/sport/velosipedy/',
    '/sport/rolikovye-konki/',
    '/deti/samokaty/',
    '/deti/skejtbordy-price/',
    '/deti/detskie-elektro--i-velomobili/',
    '/deti/detskie-kachalki-katalki/',
    '/sport/lyzhi/',
    '/deti/detskie-lyzhi-price/',
    '/deti/sanki/',
    '/deti/tovary-dlya-kormleniya-price/',
    '/deti/detskoe-pitanie/',
    '/krasota/detskie-vesy/',
    '/deti/tovary-dlya-detskogo-kupaniya/',
    '/deti/detskaya-gigiena-price/',
    '/deti/hodunki/',
    '/deti/detskie-gorshki-i-sidenya-price/',
    '/deti/podguzniki-i-trusiki/',
    '/deti/tovary-dlya-detej-raznoe-price/',
    '/deti/detskaya-bezopasnost-price/',
    '/deti/ryukzaki-kenguru-slingi-vozhzhi/',
    '/deti/odezhda-dlya-kormleniya-price/',
    '/deti/termokontejnery-i-sumki-price/',
    '/deti/gigiena-dlya-mam-price/',
    '/deti/podushki-dlya-kormleniya-price/',
    '/deti/radio--videonyani/',
    '/deti/molokootsosy/',
    '/deti/podogrevateli-sterilizatory/',
    '/deti/tovary-dlya-mam-raznoe-price/',
    '/dom/ofisnye-i-kompyuternye-stoly/',
    '/sport/ryukzaki/',
    '/deti/tetradi-i-bloknoty-price/',
    '/deti/dnevniki-shkolnye-price/',
    '/deti/shkolnye-penaly-price/',
    '/office/kalkulyatory/',
    '/deti/tovary-dlya-zhivopisi-price/',
    '/deti/molberty-doski-dlya-risovaniya-price/',
    '/deti/obuchayuschie-programmy-dlya-detej-i-shkolnikov-price/',
    '/office/kancelyarskie-tovary-price/',
    '/deti/shkolnaya-forma-dlya-devochek-price/',
    '/deti/shkolnaya-forma-dlya-malchikov-price/',
    '/deti/bodiki-chelovechki-polzunki-price/',
    '/deti/odezhda-na-vypisku-price/',
    '/deti/nabor-dlya-krescheniya-price/',
    '/deti/detskie-kurtki-palto-price/',
    '/deti/detskie-shapki-price/',
    '/deti/detskie-kostyumy-price/',
    '/deti/detskie-shtany-price/',
    '/deti/detskie-kolgotki-noski-price/',
    '/deti/detskie--futbolki-reglany-price/',
    '/deti/detskie-platya-yubki-price/',
    '/deti/detskie-kombinezony-price/',
    '/deti/detskoe-nizhnee-bele-price/',
    '/deti/detskie-kupalniki-plavki-price/',
    '/deti/detskaya-odezhda-price/',
    '/deti/detskaya-obuv-price/',
    '/deti/detskaya-bizhuteriya-aksessuary-price/',
);

#foreach my $url ( @lot_urls ) { 
#    $url = 'http://hotline.ua'.$url.'?sort=1&p=%d';
#    CmpParser->new( $url, 'cp1251', 1  )->get_prods_list();
#}

############################################
#my @url_one = ( 'computer/skanery' );
############################################

    foreach my $l ( @{ CmpParser->new( $url, 'cp1251', 1, 1, 0 )->get_prods_list() } ){
        print $l->{name}."\n--\n"; print $l->{href}."\n--\n"; print $l->{price}."\n--\n"; print $l->{img}."\n--\n"; print $l->{desc}."\n--\n";
    }

#my @url_bad = ( 'computer/zhestkie-diski', 'computer/sumki-kejsy-ryukzaki-dlya-noutbukov' );

1;
