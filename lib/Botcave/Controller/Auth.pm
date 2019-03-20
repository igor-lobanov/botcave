package Botcave::Controller::Auth;

use Mojo::Base 'Mojolicious::Controller';
use Digest::SHA1 qw(sha1_base64);
use Botcave::Language::en;

sub login {
    my $c = shift;
    $c->render;
}

sub post_login {
    my $c = shift;
    my $data = $c->req->json;
    my $url = $data->{url} || '/';
    
    my $lang = $c->app->lang($c->stash('lang'));

    # validate email and password
    my $validation = $c->validation;

    $validation->validator->add_check(valid_account => sub {
        my ($validation, $topic, $value, $c) = @_;
        my $agent = $c->model('Agents')->find_by(
            email       => $validation->output->{email},
            password    => sha1_base64($validation->output->{password})
        ) || return 1;
        $validation->output({ agentid => $agent->{id} });
        return 0;
    });

    $validation->input({ map { $_ => $data->{$_} } qw( email password ) });

    my @errors;
    if ($validation->has_data) {
        $data = $validation->required('email', 'trim')->required('password', 'trim')->valid_account($c)->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'login', $_, $validation->error($_)->[0] ) };
            }
        }
        else {
            $c->session(agentid => $data->{agentid}, expiration => 365*24*60*60);
            return $c->render(json => {
                success     => \1,
                redirect    => $url,
            });
        }
    }
    else {
        push @errors, $lang->errors->{'login:nodata'};
    }

    $c->render(json => {
        success => \0,
        message => $lang->titles->{'modal:errors'},
        errors  => \@errors,
    });
}

sub logout {
    my $c = shift;
    $c->session( expires => 1 );
    $c->redirect_to( '/' );
}

1;
