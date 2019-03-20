package Botcave::Model::Customers;

use Mojo::Base 'Botcave::Model::Base';

sub list    { shift->backend->customers_list(@_) }
sub find_by { shift->backend->find_customer_by(@_) }

1;

__END__
