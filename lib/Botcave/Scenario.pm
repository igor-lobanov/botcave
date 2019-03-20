package Botcave::Scenario;

use Mojo::Base -base;

has 'app';
has 'id';

sub run {
    my ($self, $payload) = @_;
    my $scenario = $self->app->model('Scenarios')->find_by(id => $id, -actors => 1);
    $self;
}

1;

