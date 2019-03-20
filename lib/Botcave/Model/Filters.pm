package Botcave::Model::Filters;

use Mojo::Base 'Botcave::Model::Base';

sub find_by     { shift->backend->find_filter_by(@_) }
sub list        { shift->backend->filters_list(@_) }
sub add         { shift->backend->filter_add(@_) }
sub update      { shift->backend->filter_update(@_) }
sub unvalidate  { shift->backend->filter_unvalidate(@_) }

1;

__END__
