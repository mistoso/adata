package Core::Mail::Parse;

use Base::StTemplate;
use Cfg;

sub do {
    my $msg    = shift;
    my $params = shift;
    my $parsed_msg = '';
    my $stt = Base::StTemplate->instance($cfg->{'stt'});
    $stt->SetAndGenerate(\$msg,\$parsed_msg,$params);
    return $parsed_msg; 
}

sub headers {
    my $msg = shift;
    my $headers = ();
    foreach (split /\n/, $msg){
          s/\s*$//g;
          s/^\s*//g;
          /^(.*)?:(.*)$/;
          $heasers->{$1} = $2;
    }
    return $heasers;
}

1;
