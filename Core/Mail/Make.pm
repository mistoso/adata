package Core::Mail::Make;

use Core::Mail::Config;
use Core::Mail::MIME;
use Logger;

use Data::Dumper;
use Net::SMTP;
use File::Temp qw/ tempfile /;

sub new {
    my $class = shift;
    my $headers = shift;

    $class = ref $class if ref $class;
    my $self = bless {}, $class;

    $headers->{From} = Core::Mail::Config::from();

    if ($headers->{Bcc}) {
        $headers->{Bcc} .= Core::Mail::Config::bcc();
    }
    else {
        $headers->{Bcc} = Core::Mail::Config::bcc();
    }

    $log->debug("Core::Mail::Make: Got headers ".Dumper($headers));
    
    $headers->{charset} = 'cp1251' unless $headers->{charset};
        $headers->{force_to_utf8} = 1;

    $self->{msg} = Core::Mail::MIME->new($headers);

    $self;
}

sub add_html {
    my $self      = shift;
    $self->{html} = shift;

    $log->debug("Core::Mail::Make: Got html ".$self->{html});

    $self->__find_images();
    $self->__get_images();
    $self->__make_images();
    #$self->__cleanup_tmp_images();

    $self->{msg}->addText('html',$self->{html});
}

sub add_text {
    my $self = shift;
    my $data = shift;

    $log->debug("Core::Mail::Make: Got text ".$data);

    $self->{msg}->addText('plain',$data);
}

sub as_string {
    my $self = shift;
    return  $self->{msg}->compile;
}

sub __find_images {
    my $self = shift;
    $self->{images} = ();
    foreach (split /\n/,$self->{html}) {
        # image pattern here please
        while (s/url\((.*?)\)//) {
            $self->{images}->{$1} = () if $1;
        }
        while (s/img src="(.*?)"//) {
            $self->{images}->{$1} = () if $1;
        }
        while (s/img src='(.*?)'//) {
            $self->{images}->{$1} = () if $1;
        }
    }
}

sub __get_images {
     my $self = shift;

     foreach my $key (keys %{$self->{images}}) {

         #my (undef, $tmp) = tempfile('email_imageXXXXXXXXXXXX', DIR => Core::Mail::Config::tmp_dir ,OPEN => 0);
         #system("/usr/bin/wget '".Core::Mail::Config::public_domain().$key."' -O $tmp");

             my $tmp = Core::Mail::Config::root_path().$key;

             if (-s $tmp > 100 and not -d $tmp) {
                 $key =~ /\/([\w|\.]*)$/i;

                 $self->{images}->{$key}->{new} = $1;
                 $self->{images}->{$key}->{new} =~ s/\W/_/g;
                 $self->{images}->{$key}->{file_path} = $tmp;
             }  
             else {

                delete $self->{images}->{$key};
             }  
     }
}

sub __make_images {
     my $self = shift;

     foreach my $key (keys %{$self->{images}}) {
        $self->{html} =~ s/\Q$key\E/cid:$self->{images}->{$key}->{new}/g;

        my $content = '';
        {
            local $/ = undef;
            open IN, $self->{images}->{$key}->{file_path} or $log->fatal("Error opening $self->{images}->{$key}->{file_path} ($key): $!");
            binmode IN;
            $content = <IN>;
            close IN;
        }

        $self->{msg}->addAtachment('image/gif',$self->{images}->{$key}->{new},$content);
     }
}

sub __cleanup_tmp_images {
     my $self = shift;

     foreach my $key (keys %{$self->{images}}) {
        unlink $self->{images}->{$key}->{tmp};
     }
}
1;
