package Botcave::Plugin::Botplace;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Loader qw(load_class find_modules);
use Mojo::File qw(path);
use Mojo::Util qw(decode);
use Mojo::JSON qw(from_json);
use Mojo::Collection;
use Carp qw(carp croak);
use Data::Dumper;

has 'app';
has 'bots'              => sub {{}};
has 'events'            => sub {{}};
has 'event_modules'     => sub {{}};
has 'filter_modules'    => sub {{}};
has 'bot_modules'       => sub {{}};

sub register {
    my ($pl, $app, $conf) = @_;

    $pl->app($app);

    # find and load bot modules
	my @bot_modules = find_modules('Botcave::Bot');
    my %found;
    for my $pm (grep /^Botcave::Bot::[^:]+$/, @bot_modules) {
        my ($type) = ($pm =~ /^Botcave::Bot::([^:]+)$/);
		next if $found{$type};
		if (my $e = load_class($pm)) {
            carp ref $e ? "Loading $pm exception: $e" : "$pm not found";
        }
        $pl->bot_modules->{$type} = $pm->new(app => $app);
        $found{$type}++;
    }

    # metabot helper to access bot conf and other methods and attributes
    # metabot('Telegram')->conf
    $app->helper(metabot => sub { $pl->bot_modules->{$_[1]} });

    # events
    for my $type (keys %found) {
        for my $event (keys %{ $pl->bot_modules->{$type}->events }) {
            $pl->events->{$event} = {
                type        => $type,
                name        => $event,
                description => $pl->bot_modules->{$type}->events->{$event}
            };
        }
    }
    $app->helper(event_list => sub {
        Mojo::Collection->new(sort keys %{ $pl->events });
    });

    # event handlers
    for my $ns ('Botcave::EventModule', map { 'Botcave::EventModule::' . $_ } keys %found) {
        my @modules = find_modules($ns);
        for my $pm (grep !/^Botcave::EventModule::Base$/, @modules) {
            my ($name) = $pm =~ /Botcave::EventModule::(.*)/;
            my $e = load_class($pm);
            croak "Loading '$pm' failed: $e" if ref $e;
            $pl->event_modules->{$name} = $pm->new(app => $app);
        }
	}
    $app->helper(event_module => sub { $pl->event_modules->{$_[1]} });
    $app->helper(event_module_list => sub {
        Mojo::Collection->new(sort keys %{ $pl->event_modules });
    });

    # filter modules
    for my $ns ('Botcave::Filter', map { 'Botcave::Filter::'.$_ } keys %found) {
        my @modules = find_modules($ns);
        for my $pm (grep !/^Botcave::Filter$/, @modules) {
            my ($name) = $pm =~ /Botcave::Filter::(.*)/;
            my $e = load_class($pm);
            croak "Loading '$pm' failed: $e" if ref $e;
            $pl->filter_modules->{$name} = $pm->new(app => $app);
        }
	}
    $app->helper(filter_module => sub { $pl->filter_modules->{$_[1]} });
    $app->helper(filter_module_list => sub {
        Mojo::Collection->new(sort keys %{ $pl->filter_modules });
    });

    # helper
    $app->helper(botplace => sub { $pl });

    # init bots
    $pl->init_bots;

    $pl;
}

sub init_bots {
    my ($self, $botid) = @_;

    for my $bot ($self->app->model('Bots')->list($botid ? (id => $botid) : (), -scenarios => 1)->each) {
        if (
            exists($self->bot_modules->{ $bot->{type} })
            && $self->bot_modules->{ $bot->{type} }->can('bot')
        ) {
            my $agent = $self->bot_modules->{ $bot->{type} }->bot($bot);
            $self->bots->{ $bot->{id} } = $agent;
            if ($bot->{scenarios} && @{ $bot->{scenarios} }) {
                # group scenarios by event
                my %events;
                for my $scenario (@{ $bot->{scenarios} }) {
                    $events{$scenario->{event}} ||= [];
                    push @{ $events{$scenario->{event}} }, $scenario;
                }
                # resubscribe to event
                for my $event (keys %events) {
                    $agent->unsubscribe($event)->on($event => sub {
                        my ($b, @payload) = @_;
                        $self->app->enqueue_bot_event($bot, $_, @payload) for @{ $events{$event} };
                    });
                }
            }
        }
    }

    $self;
}

sub bot {
    $_[0]->bots->{$_[1]};
}

1;

