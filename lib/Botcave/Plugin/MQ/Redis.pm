package Botcave::Plugin::MQ::Redis;

use Mojo::Base 'Botcave::Plugin::MQ::Base';
use Redis;

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(app => $args{app});
    $self->publisher(Redis->new(%{$args{config}}));
    $self->subscriber(Redis->new(%{$args{config}}));
    $self;
}

# subscriber functions
sub subscribe {
	my ($self, $event, $cb) = @_;
	$self->subscriber->psubscribe($event, $cb);
	$self;
}

sub unsubscribe {
	my ($self, $event, $cb) = @_;
	$self->subscriber->punsubscribe($event, $cb);
	$self;
}

sub wait {
	my $self = shift;
	$self->subscriber->wait_for_messages(0) if $self->subscriber->is_subscriber;
	$self;
}

# publisher functions
sub publish {
	my ($self, $event, $msg) = @_;
	$self->publisher->publish($event, $msg);
	$self;
}

1;

