package Botcave::Model::Base;

use Mojo::Base -base;

has 'backend';
has 'app';

# $obj->method([event_obj], 'foo' => 'bar')
# $obj->method([event_obj], {'foo' => 'bar'})
# _args => ($self, $event, $param)
sub _args {
    my $self = shift;
    my $event = shift if ref $_[0] eq 'Botcave::Event';
    my $param = @_==1 ? shift : {@_};
    return ($self, $event, wantarray ? %$param : $param);
}

1;

__END__
