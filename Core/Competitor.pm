package Core::Competitor;

use Logger;
use Data::Dumper;

use LWP::UserAgent;
use XML::XPath;
use XML::XPath::XMLParser;
use HTML::TreeBuilder;

use Encode;
use Clean;

sub new() { 
    my ( $class ) = shift; 
    my ( $self  ) = { competitor  => shift };  
    bless ( $self, $class ); 
    return $self; 
}

sub req(){
    my ( $self, $l ) = @_;  
    
    return 0 unless $l;
    
    my $u = LWP::UserAgent->new(); 
    my $s = $u->get( $self->url_ex( $l ) ); 
    my $c = $s->content();

    $c =~ s/[\n+|\t+|\r+|&|;|1 ||‘‘| ]/ /g; 
    $c =~ s/&[a-z]{2,4};/ /g; 
    $c =~ s/\s{2,}/ /g;
  
    #Encode::from_to( $c, "cp1251", "utf8" ) ;
  
    return $c;
}

sub soundmaster(){
    my $self = shift;
    my @buf;
    my $prod_cnt;
    ######

    if($self->{competitor}->{paged} > 0){

        for( my $i = $self->{competitor}->{paged}; 1; $i++ ){ 
        ######

            $prod_cnt = 0;

            my $cnt = $self->req(sprintf($self->{competitor}->{listlink},$i));

            my $xml = HTML::TreeBuilder->new_from_content($cnt)->as_XML();
            
            my $xp  = XML::XPath->new( xml => $xml );

            my $nodeset = $xp->find('//div[@class="code"]/table/tr'); # find all paragraphs
            
            foreach my $node ($nodeset->get_nodelist){
                $prod_cnt++;

                $xp = XML::XPath->new(context => $node);

                binmode STDOUT, ':utf8';

                my $info1 = $xp->find('//strong')->string_value;
                my $info2 = $xp->find('//a/@href')->string_value;
                my $info3 = $xp->find('//span[@style="font-weight:bold"]')->string_value || 0;

                Encode::_utf8_off($info1); Encode::from_to($info1, 'utf-8', 'utf8'); 
                Encode::_utf8_off($info2); Encode::from_to($info2, 'utf-8', 'utf8'); 
                Encode::_utf8_off($info3); Encode::from_to($info3, 'utf-8', 'utf8');

                $info3 =~ s/[^0-9\.]+//g;

	            push @buf,{ 
                    name  => $info1, 
                    href  => $info2,
                    price => $info3, 
                };
            }
            last if $prod_cnt == 0;

        ######
        }
    }
    ######
    return \@buf;
}
sub musiclife(){
    my $self = shift;
    my @buf;
    my $prod_cnt;
    ######
    if($self->{competitor}->{paged} > 0){ 

    for( my $i = $self->{competitor}->{paged}; 1; $i++ ){ 

    ######
    $prod_cnt = 0;
    print Dumper($self->{competitor});

    my $xml = HTML::TreeBuilder->new_from_content($self->req(sprintf($self->{competitor}->{listlink},$i)))->as_XML();
    my $xp = XML::XPath->new( xml => $xml );
    my $nodeset = $xp->find('//div[@class="clearf"]'); # find all paragraphs

    foreach my $node ($nodeset->get_nodelist){
        $prod_cnt++; 
        binmode STDOUT, ':utf8';
        $xp = XML::XPath->new(context => $node);
        my $info1 = $xp->find('//span[@class="name24"]/a')->string_value;
        my $info2 = $xp->find('//span[@class="name24"]/a/@href')->string_value;
        my $info3 = $xp->find('//span[@class="price"]')->string_value || 0;

        Encode::_utf8_off($info1);
        Encode::from_to($info1, 'utf-8', 'utf8'); 
        Encode::_utf8_off($info2);
        Encode::from_to($info2, 'utf-8', 'utf8'); 
        Encode::_utf8_off($info3);
        Encode::from_to($info3, 'utf-8', 'utf8'); 
        $info3 =~ s/[^0-9]+//g;
	    push @buf,{ 
	        name  => $info1, 
	        href  => $info2,
	        price => $info3, 
	    };
    }
    last if $prod_cnt == 0;
    ######
    }
    }
    ######
    return \@buf;
}

sub url_ex(){
    my $self = shift;
    my $url  = shift;
    $url =~ s/\/Page-1-10\.html$/\.html/g;
    return $url;
}
1;

