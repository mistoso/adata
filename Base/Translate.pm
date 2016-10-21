package Base::Translate;

require Exporter;
our @ISA = ('Exporter');
our @EXPORT = qw(translate);

use Encode qw(define_encoding);
use Encode::MIME::Name;
use Encode::Guess;
use utf8;

sub translate {
	my $class = shift; 
	my $word = shift; 
	my $decoder = guess_encoding($word);
#	$decoder =  guess_encoding($word,'cp-1251') unless ref($decoder);
	my $utf8 = $decoder->decode($word);
	$utf8    = $word unless ref($decoder);
	return _translit($utf8);
}
sub _translit {
	my $text = shift;
	my %mchars = (
		'ж'=>'zh','ц'=>'ts','ч'=>'ch','ш'=>'sh','щ'=>'sch','ю'=>'ju' ,
		'я'=>'ja','Ж'=>'Zh','Ц'=>'Ts','Ч'=>'Ch','Ш'=>'Sh' ,'Щ'=>'Sch',
		'Ю'=>'Ju','Я'=>'Ja','Ъ'=>''  ,'ъ'=>''  ,'ь'=>''   ,'Ь'=>''   ,
		'ґ'=>'g' ,'є'=>'e' ,'ї'=>'i' ,'і'=>'i' ,'Ґ'=>'G'  ,'Ї'=>'I'  ,
		'Є'=>'E' ,'І'=>'I'
	);
	for my $c (keys %mchars) { $text =~ s/$c/$mchars{$c}/g; }
	$text =~ y/абвгдеёзийклмнопрстуфхыэ/abvgdeezijklmnoprstufhye/;
	$text =~ y/АБВГДЕЁЗИЙКЛМНОПРСТУФХЫЭ/ABVGDEEZIJKLMNOPRSTUFHYE/;
	$text =~ s/\W/\-/g;
	$text =~ s/_/\-/g;
	$text =~ s/\-*$//g;
	$text =~ s/^\-*//g;
	$text =~ s/\-{2,}//g;
	$text = lc($text);
	return $text;
}
1;
