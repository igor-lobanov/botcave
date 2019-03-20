package Botcave::EventModule::Telegram::AutoReply;

use Mojo::Base 'Botcave::EventModule::Base';
use Data::Dumper;

has 'events'    => sub {{
    'Telegram::NewUpdate' => 1
}};
has processor   => sub { require Text::Caml; Text::Caml->new; };

sub run {
    my ($self, $bot, $event, $episode, $payload) = @_;
	my $agent = $self->app->botplace->bot($bot->{id});

    $payload->{dump}=Dumper($payload);
	if ($agent->api->sendMessage({
        chat_id => $payload->{message}{chat}{id},
        text    => $self->processor->render($self->config, $payload),
	})) {
        return $self->result(
            success => 1,
        );
    }
    else {
        return $self->result(
            success => 0,
            message => $agent->api->error,
        );
    }
}

sub config {
    my ($self) = @_;
    <<EOT;
Hello, {{message.from.first_name}}!
{{#message.entities}}{{&type}}{{/message.entities}}
{{&dump}}
EOT
}

sub ctl_config {
    my ($self, $c) = @_;
}

1;
