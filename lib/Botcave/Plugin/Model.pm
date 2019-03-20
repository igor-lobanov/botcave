package Botcave::Plugin::Model;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw(load_class find_modules);
use Scalar::Util 'weaken';
use Carp 'croak';

has 'app';
has 'backend';
has 'modules' => sub {{}};

sub register {
    my ($self, $app, $conf) = @_;

    $self->app($app);

    if ($conf->{backend}) {
        croak "You must pass one backend in constructor" if ~~keys %{$conf->{backend}} != 1; 
        for (keys %{$conf->{backend}}) {
            my $class = 'Botcave::Model::Backend::' . $_;
            my $backend = $self->load_backend($class, $conf->{backend}{$_});
            $self->backend($backend);
        }
    }

    my @model_packages = find_modules('Botcave::Model');
    for my $pm (grep !/^Botcave::Model::(?:Base|Backend)$/, @model_packages) {
        my ($basename) = $pm =~ /Botcave::Model::(.*)/;
        $self->add_model($basename, $pm, $self->backend);
    }

    # helpers
    $self->app->helper(model => sub {
        my ($c, $name) = @_;
        return $name ? $self->get_model($name) : $self->modules;
    });
    $self->app->helper(model_manager => sub { $self });

    return $self;
}

sub get_model {
    my ($self, $model) = @_;
    return $self->modules->{$model} || croak "Unknown model '$model'";
}

sub load_backend {
    my ($self, $package, $conf) = @_;
    my $e = load_class $package;
    croak ref $e ? $e : qq{Backend "$package" missing} if $e;
    #$package->new($conf);
    my $backend = $package->new($conf);     # required?
    weaken $backend->model($self)->{model}; # required?
    $backend;                               # required?
}

sub add_model {
    my ($self, $name, $package, $backend) = @_;
    my $e = load_class($package);
    croak "Loading '$package' failed: $e" if ref $e;
    $self->modules->{$name} = $package->new(backend => $backend || $self->backend, app => $self->app);
}

1;

__END__

