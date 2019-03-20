package Botcave::Filter;

use Mojo::Base -base;

has 'app';
has 'events' => sub {{}};

sub check {
    my ($self, $conf, $payload) = @_;
    return 1;
}

sub compatible_event { $_[1] ? exists $_[0]->events->{$_[1]} : 0 }

1;

__END__

=encoding utf8

=head1 NAME

B<Botcave::Filter> - base class for filter modules

=head1 SYNOPSIS

    package Botcave::Filter::MyFilter;

    use Mojo::Base 'Botcave::Filter';

    sub config {
        my ($self, $c) = @_;

        # filter already exists in stash
        my $filter = $c->stash('filter');

        $c->render(text => 'My filter configuration');
    }

    sub post_config {
        my ($self, $c) = @_;

        # filter already exists in stash
        my $filter = $c->stash('filter');

        $c->render(text => 'My filter configuration');
    }

    sub util {
        my ($self, $c) = @_;

        # filter already exists in stash
        my $filter = $c->stash('filter');

        $c->render(text => 'My filter util function');
    }

    sub check {
        my ($self, $payload) = @_;

        # check logic here
        # function returns 1 in case of successful check (matching condition)
        # or 0 in other case
        # ...
    }

    1;

=head1 DESCRIPTION

Base class for creating filter modules. Filters used in scenarios to make decision about executing
episode.

=head1 METHODS

=head2 check

Method checks event payload and returns 1 (true) or 0 (false). As a rule this method redefined in
successor class.

=head2 compatible_event

Method checks if filter module can be used with some event. Compatible events defined in attribute
B<events> of successor. This method is used by Botcave to determine is filter can be used in episode.

    $c->botplace->filter_module('MyFilter')->compatible_event('Some::Event')

=head1 METHODS DEFINED IN SUCCESSORS

Class B<Botcave::Filter> have not defined these methods. They can be defined in successor class.

=head2 config

Successor class can define method B<config> which can be used for displaying filter configuration
form. Method called as controller method after B<GET> request to route:

    /admin/filter/:id/config

=head2 post_config

Successor class can define method B<post_config> which can be used for processing POST-request
from filter configuration form. Method called as controller method after B<POST> request to route:

    /admin/filter/:id/util

=head2 util

Successor class can define method B<util> which can be used for helper requests from filter
configuration form.

Application defines such routes for this function (GET and POST)

    /admin/filter/:id/util/:function
    /admin/filter/:id/util

:id contain filter ID, :function can be used if you need more then 1 util subroutine

    /admin/filter/:id/util/func1
    /admin/filter/:id/util/func2

In case of multiple util functions you can select them in B<util> function in such way:

    sub util {
        my ($self, $c) = @_;

        my $function = $c->stash('function');
        if ($function eq 'func1') {
            return $self->util_func1($c);
        }
        elsif ($function eq 'func2') {
            return $self->util_func2($c);
        }
        else {
            return $c->reply->not_found;
        }

    }

    sub util_func1 {
        my ($self, $c) = @_;
        $c->render(text => 'FUNCTION 1');
    }

    sub util_func2 {
        my ($self, $c) = @_;
        $c->render(text => 'FUNCTION 2');
    }

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut

