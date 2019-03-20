package Botcave::Model::Agents;

use Mojo::Base 'Botcave::Model::Base';

sub find_by { shift->backend->find_agent_by(@_) }
sub list    { shift->backend->agent_list(@_) }
sub add     { shift->backend->agent_add(@_) }

sub generate_password { shift; join '', @_[ map{ rand @_ } 1 .. shift ] }

1;

__END__
