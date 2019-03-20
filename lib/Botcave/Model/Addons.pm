package Botcave::Model::Addons;

use Mojo::Base 'Botcave::Model::Base';

sub find_by     { shift->backend->find_addon_by(@_) }
sub list        { shift->backend->addons_list(@_) }
sub activate    { shift->backend->addon_activate(@_) }
sub deactivate  { shift->backend->addon_deactivate(@_) }
sub add         { shift->backend->addon_add(@_) }
sub unvalidate  { shift->backend->addon_unvalidate(@_) }

1;

__END__
