package Botcave::Model::Updates;

use Mojo::Base 'Botcave::Model::Base';

sub add     { shift->backend->update_add(@_) }
sub find_by { shift->backend->find_update_by(@_) }

1;

__END__
