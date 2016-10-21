package Core::Mail::Storage::Query;

use Model::MailQuery;

sub save {
    my $message = shift;
    my $msg = Model::MailQuery->new({
            message => $message,
            sent => 0,
        });
    return $msg->save();
}

sub list {
    return Model::MailQuery->list();
}

1;
