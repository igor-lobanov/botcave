package Botcave::Model::Scenarios;

use Mojo::Base 'Botcave::Model::Base';

sub find_by     { shift->backend->find_scenario_by(@_) }
sub list        { shift->backend->scenarios_list(@_) }
sub add         { shift->backend->scenario_add(@_) }
sub update      { shift->backend->scenario_update(@_) }
sub unvalidate  { shift->backend->scenario_unvalidate(@_) }

1;

__END__
