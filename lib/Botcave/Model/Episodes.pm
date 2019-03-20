package Botcave::Model::Episodes;

use Mojo::Base 'Botcave::Model::Base';

sub find_by     { shift->backend->find_episode_by(@_) }
sub list        { shift->backend->episodes_list(@_) }
sub add         { shift->backend->episode_add(@_) }
sub update      { shift->backend->episode_update(@_) }
sub unvalidate  { shift->backend->episode_unvalidate(@_) }

1;

__END__
