package Botcave::Model::Backend;

use Mojo::Base -base;
use Carp 'croak';

has 'model';

sub _args {
    my $self = shift;
    return @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
}

sub DESTROY {}

sub AUTOLOAD {
    my $sub = our $AUTOLOAD;
    $sub =~ s/.*:://;
    croak "Method '$sub' not implemented by subclass";
}

1;

