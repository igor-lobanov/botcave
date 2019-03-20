package Botcave::Addons::InternalMail;

use Mojo::Base 'Botcave::Addons::Base';

sub init {
    my $self = shift;

    # add links to application
    $self->app->app_links->push({
        href        => '/board/intmail',
        title       => 'Internal Mail',
        ref         => 'board:internal_mail',
        section     => 'board',
        sublinks    => [{
            href    => '/board/intmail/inbox',
            title   => 'Inbox',
            ref     => 'board:internal_mail:inbox',
        }],
    });

    # routes
    my $logged_in = $self->app->routes->find('logged_in');
    $logged_in->get('/board/intmail')->to(controller => 'Addons::InternalMail::Controller', action => 'intmail');
    $logged_in->get('/board/intmail/inbox')->to(controller => 'Addons::InternalMail::Controller', action => 'inbox');

    $self;
}

package Botcave::Addons::InternalMail::Controller;

use Mojo::Base 'Mojolicious::Controller';

sub intmail {
    my $c = shift;
    $c->render('addons/internal_mail/intmail');
}

sub inbox {
    my $c = shift;
    $c->render('addons/internal_mail/inbox');
}

1;

