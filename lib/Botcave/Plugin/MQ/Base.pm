package Botcave::Plugin::MQ::Base;

use Mojo::Base -base;
use Carp 'croak';

has 'app';
has ['publisher', 'subscriber'];

sub AUTOLOAD {
    my $sub = our $AUTOLOAD;
    $sub =~ s/.*:://;
    croak "Method '$sub' not implemented by subclass";
}

1;

