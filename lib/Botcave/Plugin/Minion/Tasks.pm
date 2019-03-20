package Botcave::Plugin::Minion::Tasks;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app) = @_;

    # task for processing bot events and helper
    $app->minion->add_task(process_bot_event => sub {
        my ($job, $bot, $scenario, @payload) = @_;

        if ($scenario->{episodes} && @{ $scenario->{episodes} }) {
            for my $episode (@{ $scenario->{episodes} }) {
                # result can contain execution plan logic (for example episode can break execution of following episodes)
                my $result = $job->app->event_module($episode->{module})->execute($bot, $scenario->{event}, $episode, @payload);
                last if $result->{break};
            }
        }

        $job;
    });
    $app->helper(enqueue_bot_event => sub {shift->minion->enqueue(process_bot_event => [@_])});

    # sending mail task and helper
    $app->minion->add_task(send_email => sub { shift->app->mail(@_) });
    $app->helper(send_email => sub { shift->minion->enqueue(send_email => [@_]) });

}

1;

