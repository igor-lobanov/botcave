package Botcave::Addons::Callcenter;

use Mojo::Base 'Botcave::Addons::Base';

sub init {
    my $self = shift;

    for (qw(Calls Entries TelegramUsers)) {
        $self->app->model_manager->add_model(
            'Callcenter::' . $_,
            'Botcave::Model::Addons::Callcenter::' . $_,
            $self->app->model_manager->load_backend('Botcave::Model::Backend::CallcenterPg', $self->app->config->{pg})
        );
    }

    # add links to application
    $self->app->app_links->push({
        href    => '/board/callcenter',
        title   => 'Call Center',
        ref     => 'board:callcenter',
        section => 'board',
    });

    # routes
    my $logged_in = $self->app->routes->find('logged_in');
    $logged_in->get('/board/callcenter')->to(controller => 'Addons::Callcenter::Controller', action => 'callcenter');
    $logged_in->get('/board/callcenter/call/:callid' => ['callid' => qr/\d+/])->to(controller => 'Addons::Callcenter::Controller', action => 'call');

    $self;
}

package Botcave::Addons::Callcenter::Controller;

use Mojo::Base 'Mojolicious::Controller';

sub callcenter {
    my $c = shift;
    my @calls = $c->model('Callcenter::Calls')->list->each;
    $c->stash(calls => \@calls);
    $c->render('addons/callcenter/main');
}

sub call {
    my $c = shift;
    my @entries = $c->model('Callcenter::Calls')->entries(callid => $c->stash('callid'))->each;
    $c->stash(entries => \@entries);
    $c->render('addons/callcenter/call');
}

1;

