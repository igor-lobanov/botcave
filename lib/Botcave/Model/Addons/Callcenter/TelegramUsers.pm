package Botcave::Model::Addons::Callcenter::TelegramUsers;

use Mojo::Base 'Botcave::Model::Base';

sub list    { shift->backend->tg_users_list(@_) }
sub add     { shift->backend->tg_user_add(@_) }
sub find_by { shift->backend->find_tg_user_by(@_) }

1;

__END__
