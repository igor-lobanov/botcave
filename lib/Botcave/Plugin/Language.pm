package Botcave::Plugin::Language;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader;

use Carp 'croak';

has 'modules' => sub { {} };
has 'app';
has 'default';

sub register {
    my ($self, $app, $conf) = @_;

    $self->app($app);
    $self->default($conf->{default});

    my @lang_packages = Mojo::Loader::find_modules('Botcave::Language');
    for my $pm (grep { $_ ne 'Botcave::Language::Base' } @lang_packages) {
        my $e = Mojo::Loader::load_class($pm);
        croak "Loading '$pm' failed: $e" if ref $e;
        my ($lang) = $pm =~ /Botcave::Language::(.*)/;
        $self->modules->{$lang} = $pm->new(lang => $lang, app => $app)->init();
    }

    # helpers
    $app->helper(lang => sub {
        my ($c, $lang) = @_;
        return $self->get_lang($lang || $c->cookie('lang') || $self->default);
    });
    $app->helper(tl => sub {
        my ($c, $word, @args) = @_;
        chomp $word if $word;
        return $self->get_lang($c->cookie('lang') || $self->default)->translate($word, @args);
    });
    $app->helper(include_tl => sub {
        my ($c, $tmpl) = @_;
        $c->render_to_string("$tmpl." . $c->stash('lang')) || $c->render_to_string($tmpl) || '';
    });

    return $self;
}

sub get_lang {
    my ($self, $lang) = @_;
    return $self->modules->{$lang} || croak "Unknown language '$lang'";
}

1;

__END__

