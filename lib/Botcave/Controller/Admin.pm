package Botcave::Controller::Admin;

use Mojo::Base 'Mojolicious::Controller';
use Digest::SHA1 qw(sha1_base64);
use Carp 'croak';

use Data::Dumper;

sub main {
    my $c = shift;
    $c->render;
}

1;

__END__

