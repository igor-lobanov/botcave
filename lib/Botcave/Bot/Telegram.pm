package Botcave::Bot::Telegram;

use Mojo::Base 'Botcave::Bot';
use Botcave::Bot::Telegram::Agent;
use Botcave::Bot::Telegram::Types;
use Session::Token;
use Data::Dumper;

has 'app';
has 'type'      => 'Telegram';
has 'events'    => sub {{
    'Telegram::NewUpdate' => 'New incoming update'
}};
has 'conf'      => sub {{
    'fa'                => 'fa fa-telegram',
    'agent'             => 'Botcave::Bot::Telegram::Agent',
    'allowed_updates'   => [qw(
        message
        edited_message
        channel_post
        edited_channel_post
        inline_query
        chosen_inline_result
        callback_query
        shipping_query
        pre_checkout_query
    )],
}};
has 'bots'      => sub {{}};

sub init {
    my $self = shift;
    
    # Telegram types definitions and filter operations
    Botcave::Bot::Telegram::Types->new(app => $self->app);

    # Route for Telegram updates
    $self->app->routes->post('/tg/:webtoken' => [ webtoken => qr/[a-zA-Z0-9_-]+/ ])->to(cb => sub {
        my $c = shift;
        my $webtoken = $c->param('webtoken');
        if (exists($self->bots->{$webtoken})) {
            $self->bots->{$webtoken}->emit('Telegram::NewUpdate', $c->req->json);
            return $c->render(text => 'OK');
        }
        else {
            return $c->reply->not_found;
        }
    });

    $self;
}

sub bot {
    my ($self, $bot) = @_;
    $self->bots->{ $bot->{conf}{webtoken} } = $self->conf->{agent}->new(
        app     => $self->app,
        conf    => $bot->{conf},
    );
}

# controller Bots replacements
sub ctl_add {
	my ($self, $c) = @_;
    $c->render(template => 'admin/bots/telegram/add');
}

sub ctl_post_add {
	my ($self, $c) = @_;

    my $data = $c->req->json;

    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->validator->add_check(exist_token => sub {
        my ($validation, $name, $value) = @_;
        my $bot= $c->model('Bots')->find_by('conf.token' => $value);
        return $bot && $bot->{id};
    })->add_check(valid_scenario => sub {
        my ($validation, $name, $value) = @_;
        my $scenario = $c->model('Scenarios')->find_by(id => $value);
        return $scenario && $scenario->{id} && $c->metabot('Telegram')->events->{ $scenario->{'event'} } ? 0 : 1;
    })->add_check(valid_update => sub {
        my ($validation, $name, $value) = @_;
        for (@{ $c->metabot('Telegram')->conf->{allowed_updates} // []}) {
            return 0 if ($value eq $_);
        }
        return 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw(
        name token allowed_updates scenarioid max_connections
    ) });

    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation
            ->required('name', 'trim')
            ->required('token', 'trim')->exist_token
            ->optional('allowed_updates')->valid_update
            ->optional('scenarioid', 'trim')->valid_scenario
            ->optional('max_connections', 'trim')->num(1, 100)
            ->output;
		if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'bots_add_telegram', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
		else {
            $data->{conf} = {
                token       => $data->{token},
                webtoken    => Session::Token->new(entropy => 256)->get,
            };
            $data->{online} = 0;
            $data->{type} = 'Telegram';

            # check bot existance and read bot info
            my $bot = $c->metabot('Telegram')->bot({conf => $data->{conf}});
            my $me = $bot->api->getMe;

            # add bot to database
            if ($me && $me->{ok}) {
                $data->{data} = $me->{result};
                map { $data->{conf}{$_} = $data->{$_} if $data->{$_} } qw(allowed_updates max_connections);
                my $botdata = $c->model('Bots')->add($data);
                $c->botplace->init_bots($botdata->{id});
                return $c->render(json => {
                    success     => \1,
                    redirect    => '/admin/bots',
                });
            }
            else {
                push @errors, $lang->errors->{'bots_add_telegram:tg_error'} . ": " . $bot->api->error;
            }
        }
	}
    else {
        push @errors, $lang->errors->{'bots_add_telegram:nodata'};
    }

    $c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub ctl_view {
	my ($self, $c) = @_;
    $c->render(template => 'admin/bots/telegram/view');
}

sub ctl_edit {
	my ($self, $c) = @_;
    $c->render(template => 'admin/bots/telegram/edit');
}

sub ctl_post_edit {
	my ($self, $c) = @_;

    my $bot = $c->stash('bot');
    my $data = $c->req->json;
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->validator->add_check(valid_scenario => sub {
        my ($validation, $name, $value) = @_;
        my $scenario = $c->model('Scenarios')->find_by(id => $value);
        return $scenario && $scenario->{id} && $c->metabot('Telegram')->events->{ $scenario->{'event'} } ? 0 : 1;
    })->add_check(valid_update => sub {
        my ($validation, $name, $value) = @_;
        for (@{ $c->metabot('Telegram')->conf->{allowed_updates} // []}) {
            return 0 if ($value eq $_);
        }
        return 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw(
        name allowed_updates scenarioid max_connections
    ) });
    
    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation
            ->required('name', 'trim')
            ->optional('allowed_updates')->valid_update
            ->optional('scenarioid', 'trim')->valid_scenario
            ->optional('max_connections', 'trim')->num(1, 100)
            ->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'bot_edit_telegram', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            my $bot = $c->stash('bot');
            map { delete $bot->{conf}{$_}; $bot->{conf}{$_} = $data->{$_} if $data->{$_}} qw(allowed_updates max_connections);
            map { $bot->{$_} = $data->{$_} if $data->{$_} } qw(name scenarioid);
            $c->model('Bots')->update($bot);
            $c->botplace->init_bots($bot->{id});
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/bot/' . $bot->{id} . '/view',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'bot_edit_telegram:nodata'};
    }

	$c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub ctl_online {
	my ($self, $c) = @_;
    my $bot = $c->stash('bot');
	my $agent = $self->bot($bot);
	if ($agent->start) {
        $c->model('Bots')->online(id => $bot->{id});
        $c->botplace->init_bots($bot->{id});
    }
    else {
        $c->flash(alert => { title => $c->tl('Error'), text => $agent->error });
    }
    $c->redirect_to( '/admin/bot/' . $bot->{id} . '/view' );
}

sub ctl_offline {
	my ($self, $c) = @_;
    my $bot = $c->stash('bot');
	if (my $agent = $self->bots->{$bot->{conf}{webtoken}}) {
        if ($agent->stop) {
            $c->model('Bots')->offline(id => $bot->{id});
            delete $self->bots->{$bot->{conf}{webtoken}};
            $c->botplace->init_bots;
        }
        else {
            $c->flash(alert => { title => $c->tl('Error'), text => $agent->error });
        }
    }
    $c->redirect_to( '/admin/bot/' . $bot->{id} . '/view' );
}

sub ctl_delete {
	my ($self, $c) = @_;
    my $bot = $c->stash('bot');
	if (my $agent = $self->bots->{$bot->{conf}{webtoken}}) {
        if ($agent->stop) {
            $c->model('Bots')->offline(id => $bot->{id});
            $c->app->model('Bots')->unvalidate( id => $bot->{id} );
            $c->flash(alert => {title => $c->tl('Bot'), text => $c->tl('Bot deleted')});
            delete $self->bots->{$bot->{conf}{webtoken}};
            $c->botplace->init_bots;
        }
        else {
            $c->flash(alert => { title => $c->tl('Error'), text => $agent->error });
        }
    }
    $c->redirect_to( '/admin/bots' );
}

1;

__END__

