package Botcave::Controller::Board;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub main {
    my $c = shift;
    $c->render;
}

sub inbox {
    my $c = shift;
    $c->render;
}

1;

__END__

