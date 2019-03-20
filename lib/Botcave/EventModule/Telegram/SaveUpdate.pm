package Botcave::EventModule::Telegram::SaveUpdate;

use Mojo::Base 'Botcave::EventModule::Base';
use Data::Dumper;

has 'events'    => sub {{
    'Telegram::NewUpdate' => 1,
}};

sub run {
    my ($self, $bot, $event, $episode, $payload) = @_;

    $self->app->log->debug('SaveUpdate', Dumper($payload));

    (my $botid = $bot->{conf}{token}) =~ s/:.+$//;
    $self->app->model('Updates')->add({
        update_id   => $payload->{update_id},
        bot_id      => $botid,
        update      => $payload,
    });
    return $self->result(success => 1);
}

1;
