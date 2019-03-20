package Botcave::Model::Bots;

use Mojo::Base 'Botcave::Model::Base';

sub find_by     { shift->backend->find_bot_by(@_) }
sub list        { shift->backend->bot_list(@_) }
sub add         { shift->backend->bot_add(@_) }
sub online      { shift->backend->bot_online(@_) }
sub offline     { shift->backend->bot_offline(@_) }
sub update      { shift->backend->bot_update(@_) }
sub unvalidate  { shift->backend->bot_unvalidate(@_) }

1;

__END__
