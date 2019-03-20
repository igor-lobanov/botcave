package Botcave::Controller::Admin::Addons;

use Mojo::Base 'Mojolicious::Controller';
use Carp 'croak';

use Data::Dumper;

sub addon {
    my $c = shift;
    my $addon = $c->model('Addons')->find_by(id => $c->stash('id'));
    unless ($addon->{id}) {
        $c->reply->not_found;
        return 0;
    }
    $c->stash(addon => $addon);
    return 1;
}

sub list {
    my $c = shift;
    
    my @addons = $c->model('Addons')->list({valid => 1}, 'id')->each;

    $c->stash(
        addons    => \@addons,
    );
    $c->render;
}

sub view {
    my $c = shift;
    $c->render;
}

sub config {
    my $c = shift;
    
    my $addon = $c->model('Addons')->find_by(id => $c->stash('addonid'));
    return $c->reply->not_found unless ($addon->{id});

    $c->stash(
        addon => $addon,
    );
    $c->render;
}

sub start {
    my $c = shift;
    
    my $addon = $c->model('Addons')->find_by(id => $c->stash('addonid'));
    return $c->reply->not_found unless ($addon->{id});

    eval {
        # attach addon
        my $ad = $c->app->addons_manager->load_addon($addon->{module});
        $c->model('Addons')->activate(id => $addon->{id});
        $ad->routes($c->app->routes);
    } or do {
        $c->flash(alert => { title => $c->tl('Error'), text => $@ });
    };

    $c->redirect_to( '/admin/addon/' . $addon->{id} . '/view' );
}

sub stop {
    my $c = shift;
    
    my $addon = $c->model('Addons')->find_by(id => $c->stash('addonid'));
    return $c->reply->not_found unless ($addon->{id});

    eval {
        $c->model('Addons')->deactivate(id => $addon->{id});
    } or do {
        $c->flash(alert => { title => $c->tl('Error'), text => $@ });
    };

    $c->redirect_to( '/admin/addon/' . $addon->{id} . '/view' );
}

1;

__END__

