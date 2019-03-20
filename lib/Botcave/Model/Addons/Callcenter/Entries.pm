package Botcave::Model::Addons::Callcenter::Entries;

use Mojo::Base 'Botcave::Model::Base';

sub list    { shift->backend->entries_list(@_) }
sub add     { shift->backend->entry_add(@_) }

1;

__END__
