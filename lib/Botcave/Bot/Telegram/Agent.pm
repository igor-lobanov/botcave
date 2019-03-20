package Botcave::Bot::Telegram::Agent;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::URL;
use Session::Token;
use Digest::MD5 qw(md5_hex);
use Botcave::Bot::Telegram::API;

has 'app';
has 'api';
has 'conf'      => sub { {} };

sub new {
    my $self = shift->SUPER::new(@_);
    $self->init(@_);
    $self;
}

sub error {
    my ($self, $msg) = @_;
    return $self->{_error} unless $msg;
    $self->{_error} = $msg;
    return undef;
}

sub init {
    my ($self) = @_;

    # init Telegram bot API
    $self->api(Botcave::Bot::Telegram::API->new(
        token => $self->conf->{token},
    ));

    $self;
}

sub endpoint {
    my $self = shift;
    return $self->app->config->{fqdn} . '/tg/' . $self->conf->{webtoken};
}

sub stop {
    my $self = shift;
    return $self if $self->api->deleteWebhook;
    return $self->error($self->api->error);
}

sub start {
    my $self = shift;

    return $self if $self->conf->{webtoken} && $self->api->setWebhook({
        url                 => $self->endpoint,
        allowed_updates     => $self->conf->{allowed_updates} || [],
        optional(
            max_connections => $self->conf->{max_connections},
        )
    });

    # error during webhook setup
    return $self->conf->{webtoken} ? $self->error($self->api->error) : $self->error('Webtoken is not defined');
}

sub optional { my %hash = @_; map { defined $hash{$_} ? ($_ => $hash{$_}) : () } keys %hash }

1;

=encoding utf8

=head1 CONSTRUCTOR

    my $bot = new Botcave::Bot::Telegram::Agent(
        conf    => {
            token           => '12345:sghd34jygshF14ghIkl-zy5W2v1u123ew11', # required
            webtoken        => 'aH8Ytdgfrs0Jks31a',                         # required
            allowed_updates => ['message'],                                 # optional
            max_connections => 5,                                           # optional
        },
    );

=cut

__END__
