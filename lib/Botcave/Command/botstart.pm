package Botcave::Command::botstart;

use Mojo::Base 'Mojolicious::Command';
use Mojo::Util 'getopt';
use Mojo::JSON qw(from_json to_json);

# Short description
has description => "Bot's rocket site";
has usage => <<"USAGE";
$0 botstart

    Initializes online bots in networks

USAGE

# Usage message from SYNOPSIS
has usage => sub { shift->extract_usage };

sub run {
	my ($self, @args) = @_;

    getopt(\@args);

    my $app = $self->app;

    for my $botid (keys %{ $app->botplace->bots }) {
        print $botid, "\n";
    }
}

1;

