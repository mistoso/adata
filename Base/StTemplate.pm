package Base::StTemplate;

use base qw( Class::Singleton );

use Error;
use Template;
use Logger;
use Data::Dumper;
use Base::Exception;

#----------------------------------------------------------------------------------------------------
sub _new_instance {
	my $class		= shift;
	my $TTConfig    = shift;
	my $this  = undef;
	if (!$TTConfig) {
		throw StTemplate::Exception("Parameters missing to create Template Toolkit object");
	}
	$this->{'tt'}			= Template->new($TTConfig);
	$this->{"FileTemplate"}	= "";
	$this->{"FileOutput"}	= "";
	bless $this, $class;
	return $this;
}
#----------------------------------------------------------------------------------------------------
sub setTemplatePath {
	my $this				= shift;
	$this->{"FileTemplate"}	= shift;
}
#----------------------------------------------------------------------------------------------------
sub setOutputPath {
	my $this				= shift;
	$this->{"FileOutput"}	= shift;
}
#----------------------------------------------------------------------------------------------------
sub generate {
	my $this = shift;	
	my $vars = shift;
	if ($this->{"FileTemplate"} eq '') {
		 throw StTemplate::Exception("Parameter FileTemplatePath missing, cannot generate");
	}
	
	my $output = '';

    if (ref($this->{"FileTemplate"}) eq 'SCALAR' and $this->{"FileOutput"} eq '' ) {
		$this->{'tt'}->process(\$this->{"FileTemplate"}, $vars, \$output) 			|| throw StTemplate::Exception("Template Toolkit error ". $this->{'tt'}->error());
    } elsif($this->{"FileOutput"} eq '') {
		$this->{'tt'}->process($this->{"FileTemplate"}, $vars, \$output)  			|| throw StTemplate::Exception("Template Toolkit error ". $this->{'tt'}->error());
	} else {
		$this->{'tt'}->process($this->{"FileTemplate"},$vars,$this->{"FileOutput"}) || throw StTemplate::Exception("Template Toolkit error ". $this->{'tt'}->error());
	}
	return $output;
}
#----------------------------------------------------------------------------------------------------
sub SetAndGenerate {
	my $this         = shift;
	my $FileTemplate = shift;
	my $FileOutput   = shift;
	my $vars         = shift;

	$this->setTemplatePath($FileTemplate);
	$this->setOutputPath($FileOutput);

	return $this->generate($vars);
}	
#----------------------------------------------------------------------------------------------------
1;

