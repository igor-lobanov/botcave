package Botcave::Link;

use Mojo::Base -base;
use Mojo::Collection;
use Data::Dumper;

has 'href';
has 'title';
has 'ref';
has 'section';
has 'sublinks' => sub { Mojo::Collection->new };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->sublinks(Mojo::Collection->new( @{ $self->sublinks } ));
    $self->sublinks($self->sublinks->map(sub {Botcave::Link->new($_)}))
        if $self->sublinks->size;
    $self;
}

1;

