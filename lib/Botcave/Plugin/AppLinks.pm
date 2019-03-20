package Botcave::Plugin::AppLinks;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Collection;
use Botcave::Link;
use Carp 'croak';

has 'app';
has 'storage' => sub { Mojo::Collection->new };

sub register {
    my ($self, $app, $conf) = @_;

    $self->app($app);

    # helpers
    $app->helper('links' => sub {
        my ($c, $section) = @_;
        return $section ? $self->storage->grep(sub {$_->section eq $section}) : $self->storage;
    });
    $app->helper('app_links' => sub { $self });

    $self;
}

sub push { push @{shift->storage}, map { Botcave::Link->new($_) } @_ }
sub unshift {unshift @{shift->storage}, map { Botcave::Link->new($_) } @_ }
sub pop { pop @{shift->storage} }
sub shift { shift @{shift->storage} }

1;

