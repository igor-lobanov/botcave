package Botcave::Controller::Admin::Scenarios;

use Mojo::Base 'Mojolicious::Controller';
use Carp 'croak';

use Data::Dumper;

sub scenario {
    my $c = shift;
    my $scenario = $c->model('Scenarios')->find_by(id => $c->stash('id'), -episodes => 1);
    if ($scenario->{id}) {
        $c->stash(scenario => $scenario);
        return 1;
    }
    else {
        $c->reply->not_found;
        return 0;
    }
}

sub list {
    my $c = shift;
    my @scenarios = $c->model('Scenarios')->list(-episodes => 1)->each;
    $c->stash(
        scenarios   => \@scenarios,
    );
    $c->render;
}

sub add {
    my $c = shift;
    $c->render;
}

sub view {
    my $c = shift;
    $c->render;
}

sub edit {
    my $c = shift;
    $c->render;
}

sub post_edit {
    my $c = shift;
    
    my $scenario = $c->stash('scenario');
    my $data = $c->req->json;
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->input({ map { $_ => $data->{$_} } qw( name description ) });

    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation->required('name', 'trim')->optional('description', 'trim')->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'scenario_edit', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            # update scenario to database
            my $scenario = $c->model('Scenarios')->update(%$scenario, %$data);
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/scenarios',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'scenario_edit:nodata'};
    }

    $c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub post_add {
    my $c = shift;
    my $data = $c->req->json;
    
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->validator->add_check(valid_event => sub {
        my ($validation, $topic, $value) = @_;
        return $c->event_list->grep(qr/^\Q$value\E$/)->size ? 0 : 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw( name event description ) });

    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation
            ->required('name', 'trim')
            ->required('event', 'trim')->valid_event
            ->optional('description', 'trim')
            ->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'scenario_add', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            # add scenario to database
            my $scenario = $c->model('Scenarios')->add($data);
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/scenarios',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'scenario_add:nodata'};
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

    my $scenario = $c->stash('scenario');

    $c->model('Scenarios')->unvalidate(id => $scenario->{id});
    $c->botplace->init_bots;

    return $c->redirect_to('/admin/scenarios');
}

sub episodes {
    my $c = shift;
    my $scenario = $c->stash('scenario');
    my $episodes = $c->model('Episodes')->list(scenarioid => $scenario->{id}, -filters => 1);
    my $filters = $c->model('Filters')->list->grep(sub {
        $c->filter_module( $_->{module} )->compatible_event($scenario->{event})
    });
    my $event_modules = $c->event_module_list->grep(sub {
        $c->event_module($_)->events->{ $scenario->{event} }
    });
    $c->stash(
        episodes        => $episodes,
        filters         => $filters,
        event_modules   => $event_modules,
    );
    $c->render;
}

sub post_episode_add {
    my $c = shift;

    my $data = $c->req->json;
    my $scenario = $c->stash('scenario');
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;
    $validation->validator->add_check(valid_module => sub {
        my ($validation, $topic, $value) = @_;
        return $c->app->event_module_list->grep(qr/^\Q$value\E$/)->size ? 0 : 1;
    })->add_check(valid_filter => sub {
        my ($validation, $topic, $value) = @_;
        $c->app->model('Filters')->find_by(id => $value) ? 0 : 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw(module description filterid) });

    my (@errors, @fields);

    if ($validation->has_data) {
        $data = $validation
            ->required('module', 'trim')->valid_module
            ->optional('filterid')->valid_filter
            ->optional('description')
            ->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'scenario_episode_add', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            $data->{scenarioid} = $scenario->{id};
            $c->app->model('Episodes')->add($data);
            $c->botplace->init_bots;
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/scenario/' . $scenario->{id} . '/episodes',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'scenario_episode_add:nodata'};
    }

    $c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub episode {
    my $c = shift;
    my $scenario = $c->stash('scenario');
    my $episode = $c->model('Episodes')->find_by(id => $c->stash('id'), scenarioid => $scenario->{id});
    if ($episode->{id}) {
        $c->stash(episode => $episode);
        return 1;
    }
    else {
        $c->reply->not_found;
        return 0;
    }
}

sub episode_delete {
    my $c = shift;

    my $scenario = $c->stash('scenario');
    my $episode = $c->stash('episode');

    $c->model('Episodes')->unvalidate(id => $episode->{id});
    $c->botplace->init_bots;

    return $c->redirect_to( '/admin/scenario/' . $scenario->{id} . '/episodes' );
}

sub episode_up {
    my $c = shift;

    my $scenario = $c->stash('scenario');
    my $episode = $c->stash('episode');
    my $previous_episodes = $c->app->model('Episodes')->list(scenarioid => $scenario->{id}, position => {'<' => $episode->{position}});
    if (my $previous = $previous_episodes->last) {
        my $this_position = $episode->{position};
        $episode->{position} = $previous->{position};
        $previous->{position} = $this_position;
        $c->app->model('Episodes')->update($_) for ($episode, $previous);
    }
    return $c->redirect_to( '/admin/scenario/' . $scenario->{id} . '/episodes' );
}

sub episode_down {
    my $c = shift;

    my $scenario = $c->stash('scenario');
    my $episode = $c->stash('episode');
    my $next_episodes = $c->app->model('Episodes')->list(scenarioid => $scenario->{id}, position => {'>' => $episode->{position}});
    if (my $next = $next_episodes->first) {
        my $this_position = $episode->{position};
        $episode->{position} = $next->{position};
        $next->{position} = $this_position;
        $c->app->model('Episodes')->update($_) for ($episode, $next);
    }
    return $c->redirect_to( '/admin/scenario/' . $scenario->{id} . '/episodes' );
}

1;

__END__

