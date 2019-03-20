package Botcave::Controller;

use Mojo::Base 'Mojolicious::Controller';

# method returns json structure for controller errors on AJAX requests
sub render_json_error {
    my $c = shift;
    my $json = @_==1 ? shift : {@_};
    $c->render(json => {
        title   => $c->app->lang($c->stash('lang'))->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        %$json,
    });
}

1;

