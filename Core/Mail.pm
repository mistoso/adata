package Core::Mail;

use Core::Mail::Query;

BEGIN {
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);   $VERSION  = 1.00;  @ISA = qw(Exporter); @EXPORT = qw(Sendmail); @EXPORT_OK   = qw( );
}

sub Sendmail {
    Core::Mail::Query::queued(@_);
}

sub complex_sendmail {
    my $self = shift;
    my $mail = shift;

    open(MAIL, "| /usr/sbin/exim4 -t ");

        print MAIL "To: ".$mail->{'to'}."\n";

        if($mail->{'bcc'}){
            print MAIL "Bcc:".$mail->{'bcc'}."\n";
        }

        print MAIL "From: ".$mail->{'from'}."\n";
        print MAIL "Subject: ".$mail->{'subject'}."\n";
        print MAIL "MIME-version: 1\.0 \n";

        if($mail->{'reply_to'}){
            print MAIL "Reply-To: ".$mail->{'reply_to'}."\n";
        }
        if($mail->{'attachment_name'}){
            print MAIL "Content-Type: multipart/mixed;\n\tboundary=\"zzzboundaryzzz\"\n\n";
            print MAIL "--zzzboundaryzzz\n";
        }

        if($mail->{'html_body'}){
            print MAIL "Content-Type: multipart/alternative;\n\tboundary=\"xxxboundaryxxx\"\n\n";
            print MAIL "--xxxboundaryxxx\n";
        }

        if($mail->{'text_body'}){
            print MAIL "Content-Type: text/plain;\tcharset=iso-8859-1\n";
            print MAIL "Content-Transfer-Encoding: 7bit\n\n";
            print MAIL $mail->{'text_body'}."\n\n";
        }

        if($mail -> {'html_body'}){
            print MAIL "--xxxboundaryxxx\n";
            print MAIL "Content-Type: text/html;\tcharset=cp-1251\n";
            print MAIL "Content-Transfer-Encoding: 7bit\n\n";
            print MAIL $mail->{'html_body'}."\n\n";
            print MAIL "--xxxboundaryxxx--\n";
        }
    close(MAIL);
    return 1;
}


1;
