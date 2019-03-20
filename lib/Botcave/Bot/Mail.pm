package Botcave::Bot::Mail;

use Mojo::Base 'Botcave::Bot';

has 'app';
has 'type'      => 'Mail';
has 'conf'      => sub { {
    fa  => 'fa fa-envelope'
} };
has 'events'    => sub { {
    'Mail::MailIncoming' => 'New incoming mail'
} };

1;

__END__
