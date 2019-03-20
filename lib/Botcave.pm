package Botcave;

use strict;
use warnings;
use Mojo::Base 'Mojolicious';
use Carp 'croak';
use Data::Dumper;
use Mojo::JSON 'to_json';

#$ENV{DBI_TRACE} = 'SQL';

# this method will run once at server start
sub startup {
    my $self = shift;

    # custom paths (priority higher)
    unshift @{ $self->renderer->paths }, map {"$_/../custom/templates"} @{$self->renderer->paths};
    unshift @{ $self->static->paths }, map {"$_/../custom/public"} @{$self->static->paths};
    push @{ $self->plugins->namespaces }, 'Botcave::Plugin';
    push @{ $self->commands->namespaces }, 'Botcave::Command';

    # load configuration from botcave.json
    my $config = $self->plugin('Config');

    # DB model
    $self->plugin(model => { backend => { Pg => $self->config->{pg} } });
    # MQ broker
    $self->plugin(MQ => { backend => $self->config->{mq} });
    # application links
    $self->plugin('AppLinks');
    # language
    $self->plugin(language => $self->config->{language});
    # mail plugin
    $self->plugin(mail => $self->config->{mail});
    # botplace plugin (installs bots)
    $self->plugin('Botplace');
    # helper for json encoding in templates
    $self->helper(json => sub {Mojo::JSON::to_json($_[1])});
    # minion plugin and minion tasks
    $self->plugin(minion => $self->config->{minion});
    $self->plugin('Minion::Admin');
    $self->plugin('Minion::Tasks');

    # hook
    $self->hook(before_dispatch => sub {
        my $c = shift;
        # check session cookie
        $c->stash(agent => {}, agentid => 0);
        if (
            $c->session->{agentid}
            && (my $agent = $c->model('Agents')->find_by(id => $c->session->{agentid}))
        ) {
            $c->stash(agent => $agent, agentid => $agent->{id});
        }
        # determine language in hook in order to be available everywhere (including exception pages)
        $c->stash(lang => $c->cookie('lang') || $c->config->{language}{default} || 'en');
    });

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('home#welcome');
    $r->get('/login')->to('auth#login');
    $r->post('/login')->to('auth#post_login');
    $r->get('/logout')->to('auth#logout');
    $r->get('/setlang/:lang' => [lang => ['en', 'ru']])->to('home#setlang');

    # Check authorization
    my $logged_in = $r->under( sub {
        my $c = shift;
        return 1 if $c->stash('agentid');
        $c->flash(url => $c->tx->req->url->to_abs || '/');
        $c->redirect_to( '/login' );
        return undef;
    } )->name('logged_in');
    
    # debugging 
    $logged_in->get('/routes')->to('home#view_routes');

    $logged_in->get('/board')->to('board#main');
    
    # Controller::Admin
    $logged_in->get('/admin')->to('admin#main');

    # Controller::Admin::Agents
    $logged_in->get('/admin/agents')->to('admin-agents#list');
    $logged_in->get('/admin/agent/add')->to('admin-agents#add');
    $logged_in->post('/admin/agent/add')->to('admin-agents#post_add');
    
    # Controller::Admin::Filters
    $logged_in->get('/admin/filters')->to('admin-filters#list');
    $logged_in->get('/admin/filter/add')->to('admin-filters#add');
    $logged_in->post('/admin/filter/add')->to('admin-filters#post_add');
    my $filter_route = $logged_in->under('/admin/filter/:id' => [ id => qr/\d+/ ])->to('admin-filters#filter');
    $filter_route->get('/')->to('admin-filters#view');
    $filter_route->get('/edit')->to('admin-filters#edit');
    $filter_route->post('/edit')->to('admin-filters#post_edit');
    $filter_route->get('/delete')->to('admin-filters#delete');
    $filter_route->get('/config')->to('admin-filters#config');
    $filter_route->post('/config')->to('admin-filters#post_config');
    $filter_route->any(['GET','POST'] => '/util/:function' => [ function => qr/[a-zA-Z0-9_]+/ ])->to('admin-filters#util');
    $filter_route->any(['GET','POST'] => '/util')->to('admin-filters#util');

    # Controller::Admin::Scenarios
    $logged_in->get('/admin/scenarios')->to('admin-scenarios#list');
    $logged_in->get('/admin/scenario/add')->to('admin-scenarios#add');
    $logged_in->post('/admin/scenario/add')->to('admin-scenarios#post_add');
    my $scenario_route = $logged_in->under('/admin/scenario/:id' => [ id => qr/\d+/ ])->to('admin-scenarios#scenario');
    $scenario_route->get('/')->to('admin-scenarios#view');
    $scenario_route->get('/edit')->to('admin-scenarios#edit');
    $scenario_route->post('/edit')->to('admin-scenarios#post_edit');
    $scenario_route->get('/delete')->to('admin-scenarios#delete');
    $scenario_route->get('/episodes')->to('admin-scenarios#episodes');
    $scenario_route->post('/episode/add')->to('admin-scenarios#post_episode_add');
    my $episode_route = $scenario_route->under('/episode/:id' => [ id => qr/\d+/ ])->to('admin-scenarios#episode');
    $episode_route->get('/delete')->to('admin-scenarios#episode_delete');
    $episode_route->get('/up')->to('admin-scenarios#episode_up');
    $episode_route->get('/down')->to('admin-scenarios#episode_down');

    # Controller::Admin::Bots
    $logged_in->get('/admin/bots')->to('admin-bots#list');
    $logged_in->get('/admin/bots/add/:type' => [type => qr/[a-zA-Z0-9]+/])->to('admin-bots#add');
    $logged_in->post('/admin/bots/add/:type' => [type => qr/[a-zA-Z0-9]+/])->to('admin-bots#post_add');
    my $bot_route = $logged_in->under('/admin/bot/:id' => [ id => qr/\d+/ ])->to('admin-bots#bot');
    $bot_route->get('/online')->to('admin-bots#online');
    $bot_route->get('/offline')->to('admin-bots#offline');
    $bot_route->get('/view')->to('admin-bots#view');
    $bot_route->get('/edit')->to('admin-bots#edit');
    $bot_route->post('/edit')->to('admin-bots#post_edit');
    $bot_route->get('/delete')->to('admin-bots#delete');

    # Controller::Admin::Addons
    $logged_in->get('/admin/addons')->to('admin-addons#list');
    my $addon_route = $logged_in->under('/admin/addon/:id' => [ id => qr/\d+/ ])->to('admin-addons#addon');
    $addon_route->get('/view')->to('admin-addons#view');
    $addon_route->get('/config')->to('admin-addons#config');
    $addon_route->get('/start')->to('admin-addons#start');
    $addon_route->get('/stop')->to('admin-addons#stop');

    $logged_in->websocket('/event')->to(cb => sub {
		my $c = shift;

		# Increase inactivity timeout for connection a bit
		$c->inactivity_timeout(300);

		# callback function to subscriber
		my $rcb = sub {
			my ($msg, $event, $subscribed_event) = @_;
			$c->send(to_json({event => $event, message => $msg}));
		};

		# on close websocket
		$c->on(finish => sub {
			my ($c, $code, $reason) = @_;
			$c->app->log->debug("WebSocket closed with status $code @{[ $reason // '' ]}");
			$c->app->mq->subscriber->unsubscribe('*', $rcb);
		});

		# on websocket incoming message
		$c->on(message => sub {
			my ($ws, $msg) = @_;
			$msg =~ /^(un)?subscribe\s+(\S+)$/
                && ($1 ? $c->app->mq->subscriber->unsubscribe($2, $rcb) : $c->app->mq->subscriber->subscribe($2, $rcb));
            $c->app->mq->wait;
		});
		
	});
	$logged_in->get('/demo')->to(cb => sub {
		my $c = shift;
		$c->app->mq->publisher->publish('hello' => $c->param('msg'));
		$c->render(json => {success => \1});
	});

}

1;

