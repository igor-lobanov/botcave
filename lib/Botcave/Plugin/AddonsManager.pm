package Botcave::Plugin::AddonsManager;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'decamelize';
use Carp 'croak';

has 'app';
has 'addons' => sub {{}};

sub register {
    my ($self, $app, $conf) = @_;

    $self->app($app);

    my @addons = Mojo::Loader::find_modules('Botcave::Addons');
    my %existing;
    for my $pm (grep {$_ ne 'Botcave::Addons::Base'} @addons) {
        if (my $addon = $app->model('Addons')->find_by(module => $pm)) {
            $self->load_addon($addon->{module}) if ($addon->{active});
        }
        else {
            $app->model('Addons')->add(module => $pm);
        }
        $existing{$pm}++;
    }

    # find removed addons and delete them from database
    $app->model('Addons')->unvalidate(id => $_->{id}) for $app->model('Addons')->list->grep(sub { !$existing{ $_->{module} } })->each;

    $app->helper('addons_manager' => sub { $self });

    $self;
}

sub load_addon {
    my ($self, $module) = @_;

    return $self->addons->{$module} if $self->addons->{$module};

    my $e = Mojo::Loader::load_class($module);
    croak "Loading '$module' failed: $e" if ref $e;

    my $home = $self->app->home;
    (my $basename = $module) =~ /Botcave::Addons::(.*)/;
    my $confname = decamelize($basename);
    for my $path (qw(custom/conf/addons conf/addons)) {
        if (-e( my $file = "$home/$path/$confname.json" )) {
            $self->app->plugin('JSONConfig', {file => $file});
            last;
        }
    }

    $self->{addons}->{$module} = $module->new(app => $self->app);
    $self->{addons}->{$module}->links(Mojo::Collection->new(@{
        $self->{addons}->{$module}->links
    })) if ref $self->{addons}->{$module}->links eq 'ARRAY';

    $self->addons->{$module}->init();

    $self->addons->{$module};
}

1;

