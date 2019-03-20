package Botcave::Controller::Admin::Bots;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Loader qw(load_class);
use Data::Dumper;

sub list {
    my $c = shift;

    my @bots = $c->model('Bots')->list(-scenarios => 1)->each;
    $c->stash(
        bots    => \@bots,
    );
    $c->render;
}

sub add {
    my $c = shift;
    
    # bot specific controller
    my $type = $c->stash('type');
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    my @scenarios = $c->model('Scenarios')->list->grep(sub { exists $metabot->events->{ $_->{'event'} } })->each;
    $c->stash(
        scenarios   => \@scenarios,
    );
    return $metabot->ctl_add($c) if $metabot->can('ctl_add');
    
    # default
    return $c->render;
}

sub post_add {
    my $c = shift;

    # bot specific controller
    my $type = $c->stash('type');
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    return $metabot->ctl_post_add($c) if $metabot->can('ctl_post_add');
    
    # default
    my $data = $c->req->json;
    
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->validator->add_check(valid_scenario => sub {
        my ($validation, $name, $value) = @_;
        my $scenario = $c->model('Scenarios')->find_by(id => $value);
        return $scenario && $scenario->{id} && $metabot->events->{ $scenario->{'event'} } ? 0 : 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw( name scenarioid ) });

    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation
            ->required('name', 'trim')
            ->optional('scenarioid', 'trim')->valid_scenario
            ->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'bots_add', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            $data->{conf} = $data->{data} = {};
            $data->{online} = 0;
            $data->{type} = $type;
            my $botdata = $c->model('Bots')->add($data);
            $c->botplace->init_bots($botdata->{id});
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/bots',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'bots_add:nodata'};
    }

    $c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub bot {
    my $c = shift;

    my $bot = $c->model('Bots')->find_by(id => $c->stash('id'), -scenarios => 1);
    if ($bot->{id}) {
        $c->stash(bot => $bot);
        return 1;
    }
    else {
        $c->reply->not_found;
        return 0;
    }
}

sub online {
    my $c = shift;

    # bot specific controller
    my $bot = $c->stash('bot');
    my $type = $bot->{type};
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    return $metabot->ctl_online($c) if $metabot->can('ctl_online');
    
    # default
    $c->model('Bots')->online(id => $bot->{id});
    $c->redirect_to( '/admin/bot/' . $bot->{id} . '/view' );
}

sub offline {
    my $c = shift;

    # bot specific controller
    my $bot = $c->stash('bot');
    my $type = $bot->{type};
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    return $metabot->ctl_offline($c) if $metabot->can('ctl_offline');
    
    # default
    $c->model('Bots')->offline(id => $bot->{id});
    $c->redirect_to( '/admin/bot/' . $bot->{id} . '/view' );
}

sub view {
    my $c = shift;

    # bot specific controller
    my $type = $c->stash('bot')->{type};
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    return $metabot->ctl_view($c) if $metabot->can('ctl_view');

    # default
    $c->render;
}

sub edit {
    my $c = shift;

    # bot specific controller
    my $type = $c->stash('bot')->{type};
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    my @scenarios = $c->model('Scenarios')->list->grep(sub { exists $metabot->events->{ $_->{'event'} } })->each;
    $c->stash(
        scenarios   => \@scenarios,
    );
    return $metabot->ctl_edit($c) if $metabot->can('ctl_edit');

    # default
    $c->render;
}

sub post_edit {
    my $c = shift;

    # bot specific controller
    my $type = $c->stash('bot')->{type};
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    return $metabot->ctl_post_edit($c) if $metabot->can('ctl_post_edit');

    # default
    my $bot = $c->stash('bot');
    my $data = $c->req->json;
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->validator->add_check(valid_scenario => sub {
        my ($validation, $name, $value) = @_;
        my $scenario = $c->model('Scenarios')->find_by(id => $value);
        return $scenario && $scenario->{id} && $metabot->events->{ $scenario->{'event'} } ? 0 : 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw( name scenarioid ) });

    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation
            ->required('name', 'trim')
            ->optional('scenarioid', 'trim')->valid_scenario
            ->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'bot_edit', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            my $bot = $c->stash('bot');
            map { $bot->{$_} = $data->{$_} if $data->{$_} } qw(name scenarioid);
            $c->model('Bots')->update($bot);
            $c->botplace->init_bots($bot->{id});
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/bots',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'bot_edit:nodata'};
    }

    $c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub delete {
    my $c = shift;

    # bot specific controller
    my $bot = $c->stash('bot');
    my $type = $bot->{type};
    my $metabot = $c->metabot($type) || return $c->reply->not_found;
    return $metabot->ctl_delete($c) if $metabot->can('ctl_delete');

    # default
    $c->app->model('Bots')->unvalidate( id => $bot->{id} );
    $c->flash(alert => {title => $c->tl('Bot'), text => $c->tl('Bot deleted')});
    return $c->redirect_to( '/admin/bots' );
}

1;

__END__

