package Botcave::Controller::Admin::Agents;

use Mojo::Base 'Mojolicious::Controller';
use Carp 'croak';

sub list {
    my $c = shift;
    my @agents = $c->model('Agents')->list->each;
    $c->stash(
        agents    => \@agents,
    );
    $c->render;
}

sub add {
    my $c = shift;
    $c->render;
}

sub post_add {
    my $c = shift;
    my $data = $c->req->json;
    
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;

    $validation->validator->add_check(exist_email => sub {
        my ($validation, $topic, $value) = @_;
        return $c->model('Agents')->find_by(email => $value);
    });

    $validation->input({ map { $_ => $data->{$_} } qw( first_name last_name email ) });

    my @errors;
    if ($validation->has_data) {
        $data = $validation->required('email', 'trim')->exist_email->required('first_name', 'trim')->optional('last_name', 'trim')->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'agent_add', $_, $validation->error($_)->[0] ) };
            }
        }
        else {
            # generate password
            my $password = $c->model('Agents')->generate_password(8, 'a'..'z', 'A'..'Z', 0..9);
            $data->{password} = sha1_base64 $password;
            # add agent to database
            my $agent = $c->model('Agents')->add($data);
            # send email to agent
            my $mail = $c->render_mail(template => 'mail/newagent', agent => {
            	email       => $data->{email},
                password    => $password,
            });
            $c->send_email(
                to      => $data->{email},
                subject => 'Botcave agent registration',
                data    => $mail
            );

            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/agents',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'agent_add:nodata'};
    }

    $c->render(json => {
        success => \0,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
    });
}

1;

__END__

