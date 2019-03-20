package Botcave::Language::Base;

use Mojo::Base -base;
use Mojo::File 'path';
use Mojo::JSON 'from_json';
use Mojo::Util 'decode';

has 'app';
has 'lang';
has 'name'          => '';
has 'errors'        => sub {{}};
has 'titles'        => sub {{}};
has 'translations'  => sub {{}};

sub init {
    my $self = shift;

    my ($home, $ext, %data) = ($self->app->home, '.' . $self->lang . '.json');
    for my $path (qw(lang custom/lang)) {
        for my $file (path("$home/$path")->list->grep(qr/$ext$/)->sort->each) {
            my $hash = from_json(decode('UTF-8', $file->slurp));
            $data{$_} = { %{ $data{$_} // {} }, %{ $hash->{$_} // {} } } for (qw(errors titles translations));
        }
    }
    $self->errors( { %{ $self->errors }, %{ $data{errors} } } ) if exists($data{errors});
    $self->titles( { %{ $self->titles }, %{ $data{titles} } } ) if exists($data{titles});
    $self->translations( { %{ $self->translations }, %{ $data{translations} } } ) if exists($data{translations});

    $self;
}

sub translate {
    $_[1] ? sprintf($_[0]->translations->{$_[1]} || $_[1], splice(@_, 2)) : '';
}

1;

__END__
