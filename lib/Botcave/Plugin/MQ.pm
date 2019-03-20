package Botcave::Plugin::MQ;

use Mojo::Base 'Mojolicious::Plugin';
use Carp 'croak';
use Mojo::Loader 'load_class';

has 'app';
has 'backend';

sub register {
    my ($self, $app, $conf) = @_;

    $self->app($app);

    # load MQ backend
    croak "You must pass one MQ backend in constructor" if ~~keys %{$conf->{backend}} != 1; 
    $self->backend( $self->load_backend('Botcave::Plugin::MQ::' . $_, $conf->{backend}{$_}) ) for keys %{$conf->{backend}};

    # create mq helper
    $app->helper('mq' => sub { return $self->backend });

    $self;
}

sub load_backend {
    my ($self, $package, $conf) = @_;
    my $e = load_class $package;
    croak ref $e ? $e : qq{Backend "$package" missing} if $e;
    return $package->new(app => $self->app, config => $conf);
}

1;

