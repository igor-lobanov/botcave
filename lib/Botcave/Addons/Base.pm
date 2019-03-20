package Botcave::Addons::Base;

use Mojo::Base -base;
use Mojo::Collection;
use Botcave::Link;

has 'app';
has 'section';
has 'links' => sub { Mojo::Collection->new };

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self;
}

sub init { $_[0] }

sub routes {
    my ($self, $r) = @_;
    $self;
}

1;

