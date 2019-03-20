package Botcave::Filter::Sample;

use Mojo::Base 'Botcave::Filter';

has events => sub {{
    'Mail::MailIncoming'  => 1
}};

1;

__END__

