package Core::Mail::MIME;

use MIME::Base64;
use Text::Iconv;

sub new {
    my $class = shift;
    my $headers = shift;

    $class = ref $class if ref $class;
    my $self = bless {}, $class;

    $self->{mail} = ();

    $self->{mail}->{headers} = $headers;
    $self->{mail}->{attachment} = ();

    $self;
}        

sub compile {
    my $self = shift;

    #    if only body without attachment
    #
    #    From:
    #    To:
    #    Subject:
    #    Content-Type: multipart/alternative; boundary=$alternative_boundary
    #
    #    --$alternative_boundary
    #           Content-type: text/plain
    #
    #           base64  encoded text
    #    --$alternative_boundary
    #           Content-type: text/whatewer
    #
    #           base64  encoded text
    #    --$alternative_boundary--
    #
    #
    #    if body and attachment in mail
    #
    #    From:
    #    To:
    #    Subject:
    #    Content-Type: multipart/related; boundary=$attachment_boundary
    #    --$attachment_boundary
    #       Content-Type: multipart/alternative; boundary=$alternative_boundary
    #
    #    --$alternative_boundary
    #           Content-type: text/plain
    #
    #           base64  encoded text
    #    --$alternative_boundary
    #           Content-type: text/whatewer
    #
    #           base64  encoded text
    #    --$alternative_boundary--
    #
    #    --$attachment_boundary
    #       Content-Type: image/giff; boundary=$attachment_oundary
    #
    #           base64  encoded image
    #
    #    --$attachment_boundary
    #       Content-Type: image/giff; boundary=$attachment_oundary
    #
    #           base64  encoded image
    #
    #    --$attachment_boundary--
    #


    if ($self->{mail}->{headers}->{'force_to_utf8'}) {

        foreach my $ct (keys %{$self->{mail}->{body}}) 
        {
            #all text
            my $charset = $self->{mail}->{body}->{$ct}->{charset} || $self->{mail}->{headers}->{charset};
            my $converter = Text::Iconv->new( $charset, "UTF-8");

            $self->{mail}->{body}->{$ct}->{data} = $converter->convert($self->{mail}->{body}->{$ct}->{data});
            $self->{mail}->{body}->{$ct}->{charset} = '';
        }   

        my $converter = Text::Iconv->new( $self->{mail}->{headers}->{charset} , "UTF-8");
        $self->{mail}->{headers}->{Subject} = $converter->convert($self->{mail}->{headers}->{Subject});
        $self->{mail}->{headers}->{charset} = "UTF-8";
        

    } # force to utf-8


    my $message = '';
    my $post_headers = '';

    #headers
    $headers .= "MIME-Version: 1.0\n";
    $headers .= "From: ".$self->{mail}->{headers}->{From}."\n" if $self->{mail}->{headers}->{From};
    $headers .= "To:   ".$self->{mail}->{headers}->{To}."\n";
    $headers .= "Bcc:  ".$self->{mail}->{headers}->{Bcc}."\n" if $self->{mail}->{headers}->{Bcc};

    $self->{mail}->{headers}->{Subject} =  encode_base64($self->{mail}->{headers}->{Subject});
    $self->{mail}->{headers}->{Subject} =~ s/\s//g;

    $headers .= "Subject: =?".$self->{mail}->{headers}->{charset}."?B?".($self->{mail}->{headers}->{Subject})."?=\n";

    #body
    my $alternative_boundary = $self->__boundary();

    my $alternative = "Content-Type: multipart/alternative; boundary=".$alternative_boundary."\n\n";

    foreach my $ct (keys %{$self->{mail}->{body}}) 
    {

        $alternative .= "--".$alternative_boundary."\n";
        $alternative .= "Content-Type: text/".$ct;
        $alternative .= "; charset=".($self->{mail}->{body}->{$ct}->{charset} || $self->{mail}->{headers}->{charset});
        $alternative .= "\n";
        $alternative .= "Content-Transfer-Encoding: base64\n\n";
        
        $alternative .= encode_base64($self->{mail}->{body}->{$ct}->{data});
        $alternative .= "\n";
    }   
        $alternative .= "--".$alternative_boundary."--\n";



    #attachment
    my $attachment_boundary = $self->__boundary();
    my $attachment = '';

    if ($self->{mail}->{attachment}) {

        $post_headers .= "Content-Type: multipart/related; boundary=$attachment_boundary\n\n";
        $post_headers .= "--".$attachment_boundary."\n";
        foreach my $name (keys %{$self->{mail}->{attachment}}) 
        {
            $attachment .= "--".$attachment_boundary."\n";
            $attachment .= "Content-Type: ".$self->{mail}->{attachment}->{$name}->{ct}."; name=\"".$name."\"\n";
            $attachment .= "Content-Transfer-Encoding: base64\n";
            $attachment .= "X-Attachment-Id: ".$name."\n";
            $attachment .= "Content-ID: <".$name.">\n\n";
            $attachment .= encode_base64($self->{mail}->{attachment}->{$name}->{data})."\n";
        }
            $attachment .= "--".$attachment_boundary."--\n";
    }

    
    #make 
    $message = $headers . $post_headers . $alternative . "\n" . $attachment;

    return $message;
}

sub addText {
    my $self    = shift;
    my $ct      = shift;
    my $data    = shift;
    my $charset = shift || '';

    $self->{mail}->{body}->{$ct}->{ct}      = $ct;
    $self->{mail}->{body}->{$ct}->{data}    = $data;
    $self->{mail}->{body}->{$ct}->{charset} = $charset;
}

sub addAtachment {
    my $self    = shift;
    my $ct      = shift;
    my $name    = shift;
    my $data    = shift;

    $self->{mail}->{attachment}->{$name}->{ct}  = $ct;
    $self->{mail}->{attachment}->{$name}->{data} = $data;
}

sub header {
    my $self = shift;
    my $name = shift;

    $self->{mail}->{header}->{$name} = shift; 
}

sub __boundary {
    my $self = shift;

    my $boundary = '';
    my @chrs = ('0'..'9','a'..'z');

    foreach (0..16)
    {
        $boundary .= $chrs[rand(scalar @chrs)];
    }

    return $boundary;
}

sub dumper {
    my $self = shift;

    use Data::Dumper;
    return Dumper($self->{mail});
}

1;

