package Botcave::EventModule::Base;

use Mojo::Base -base;
use Mojo::Util 'class_to_file';

has 'bot';
has 'app';
has 'events' => sub {{}};

sub package_path { class_to_file __PACKAGE__ }

# main scenario function
sub run {
    my ($self, $bot, $event, $episode, $payload) = @_;
    return $self->result(
        success => 1,
    );
}

# filter checks payload and must return 1 (true) or 0 (false)
# depending from result run() will be executed or not
sub filter {
    my ($self, $bot, $event, $episode, $payload) = @_;


    my $result = 1;
    if ($episode->{filters} && @{ $episode->{filters} }) {
        for my $filter (@{ $episode->{filters} }) {
            if (!$self->app->filter_module($filter->{module})->check($filter->{conf}, $payload)) {
                $result = 0;
                last;
            }
        }
    }

    return $result;
}

sub execute {
    my ($self, $bot, $event, $episode, $payload) = @_;
    return $self->filter($bot, $event, $episode, $payload) ? $self->run($bot, $event, $episode, $payload) : $self->result(
        skip    => 1,
        success => 1,
    );
}

# result payload
# skip = 1 - episode skiped (for example filter returned false)
# success = 1 - episode completed without errors
# success = 0 - episode completed with errors
# error = 'error message' - error message
# break = 1 - break executing next episodes
sub result { my $self = shift; return @_ == 1 ? $_[0] : { @_ } }

# in parent class this method can be used for configuring reaction
# in Base it must not exists
# sub config { my ($self, $c) = @_; return undef }

# in parent class this method can be used for configuring reaction
# in Base it must not exists
# sub post_config { my ($self, $c) = @_; return undef }

1;
