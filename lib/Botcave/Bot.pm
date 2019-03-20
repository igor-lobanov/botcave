package Botcave::Bot;

use Mojo::Base -base;

has 'type'      => 'Base';
has 'config'    => sub {{}};
has 'events'    => sub {{}};
has 'app';

# singletons for each child class
my $singleton = {};

sub new {
    my $class = shift;
    $singleton->{$class} = $class->SUPER::new(@_)->init(@_) if !$singleton->{$class};
}

sub init { $_[0] }

sub error {
    my ($self, $msg) = @_;
    return $msg ? sub { $self->{_error} = $msg; undef }->() : $self->{_error};
}

1;

