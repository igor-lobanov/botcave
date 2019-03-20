package Botcave::Controller::Home;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub welcome {
    my $c = shift;
    $c->render;
}

sub setlang {
    my $c = shift;
    my $url = $c->req->headers->header('Referer') || '/';

    my $lang = $c->app->lang($c->stash('lang'));

    # validate lang
    my $validation = $c->validation;

    $validation->input({ map { $_ => $c->stash($_) } qw( lang ) });
    my @errors;
    if ($validation->has_data) {
        $validation->required('lang')->in('en', 'ru');
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'setlang', $_, $validation->error($_)->[0] ) };
            }
        }
        else {
            $c->cookie('lang', $c->stash('lang'), {
                expires => time+365*24*60*60,
                path    => '/',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'setlang:nodata'};
    }

    return $c->redirect_to($url);
}

sub view_routes {
    my $c = shift;
    my $rows = [];
    _walk($_, 0, $rows) for @{$c->app->routes->children};
    $c->render(text => Mojo::Util::tablify($rows), format => 'text');
}

sub _walk {
  my ($route, $depth, $rows) = @_;

  # Pattern
  my $prefix = '';
  if (my $i = $depth * 2) { $prefix .= ' ' x $i . '+' }
  push @$rows, my $row = [$prefix . ($route->pattern->unparsed || '/')];

  # Flags
  my @flags;
  push @flags, @{$route->over || []} ? 'C' : '.';
  push @flags, (my $partial = $route->partial) ? 'D' : '.';
  push @flags, $route->inline       ? 'U' : '.';
  push @flags, $route->is_websocket ? 'W' : '.';
  push @$row, join('', @flags);

  # Methods
  my $via = $route->via;
  push @$row, !$via ? '*' : uc join ',', @$via;

  # Name
  my $name = $route->name;
  push @$row, $route->has_custom_name ? qq{"$name"} : $name;

  $depth++;
  _walk($_, $depth, $rows) for @{$route->children};
  $depth--;
}

1;

__END__

