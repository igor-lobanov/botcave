package Botcave::Model::Addons::Callcenter::Calls;

use Mojo::Base 'Botcave::Model::Base';

sub list    { shift->backend->calls_list(@_) }
sub entries { shift->backend->call_entries_list(@_) }
sub find_by { shift->backend->find_call_by(@_) }
sub add     { shift->backend->call_add(@_) } #emit 'addons:call:new' event

1;

__END__
