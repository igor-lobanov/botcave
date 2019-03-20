package Botcave::Controller::Admin::Filters;

use Mojo::Base 'Botcave::Controller';
use Carp 'croak';

use Data::Dumper;

sub list {
    my $c = shift;
    
    my @filters = $c->model('Filters')->list({valid => 1})->each;

    $c->stash(
        filters => \@filters,
    );
    $c->render;
}

sub add {
    my $c = shift;
    $c->render;
}

sub post_add {
    my $c = shift;

    my $data = $c->req->json;
    my $lang = $c->app->lang($c->stash('lang'));

    # validate data
    my $validation = $c->validation;
    $validation->validator->add_check(valid_module => sub {
        my ($validation, $topic, $value) = @_;
        return $c->app->filter_module_list->grep(qr/^\Q$value\E$/)->size ? 0 : 1;
    });
    $validation->input({ map { $_ => $data->{$_} } qw(name module) });

    my (@errors, @fields);

    if ($validation->has_data) {
        $data = $validation->required('name', 'trim')->required('module', 'trim')->valid_module->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'filter_add', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            my $filter = $c->app->model('Filters')->add($data);
            my $url = $c->app->filter_module($filter->{module})->can('config')
                ? '/admin/filter/' . $filter->{id} . '/config'
                : '/admin/filters';
            return $c->render(json => {
                success     => \1,
                redirect    => $url,
            });
        }
    }
    else {
        push @errors, $lang->errors->{'filter_add:nodata'};
    }

    $c->render_json_error(
        success => \0,
        errors  => \@errors,
        fields  => \@fields,
    );
}

sub filter {
    my $c = shift;
    my $filter = $c->model('Filters')->find_by(id => $c->stash('id'));
    if ($filter->{id}) {
        $c->stash(
            filter  => $filter,
            module  => $c->app->filter_module($filter->{module}),
        );
        return 1;
    }
    else {
        $c->reply->not_found;
        return 0;
    }
}

sub view {
    my $c = shift;
    if ($c->stash('module')->can('view')) {
        $c->stash('module')->view($c);
    }
    else {
        $c->stash('filter')->{configurable} = $c->app->filter_module($c->stash('filter')->{module})->can('config');
        $c->render;
    }
}

sub edit {
    my $c = shift;
    $c->render;
}

sub post_edit {
    my $c = shift;

    my $data = $c->req->json;
    my $lang = $c->app->lang($c->stash('lang'));
    my $filter = $c->stash('filter');

    # validate data
    my $validation = $c->validation;
    $validation->input({ map { $_ => $data->{$_} } qw(name) });

    my (@errors, @fields);

    if ($validation->has_data) {
        $data = $validation->required('name', 'trim')->output;
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'filter_edit', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            $c->app->model('Filters')->update({ %$filter, %$data });
            return $c->render(json => {
                success     => \1,
                redirect    => '/admin/filters',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'filter_edit:nodata'};
    }

    $c->render_json_error(
        success => \0,
        errors  => \@errors,
        fields  => \@fields,
    );
}

sub delete {
    my $c = shift;
    $c->app->model('Filters')->unvalidate( id => $c->stash('filter')->{id} );
    $c->botplace->init_bots;
    $c->flash(alert => {title => $c->tl('Filter'), text => $c->tl('Filter deleted')});
    return $c->redirect_to( '/admin/filters' );
}

sub config {
    my $c = shift;
    return $c->stash('module')->can('config') ? $c->stash('module')->config($c) : $c->render;
}

sub post_config {
    my $c = shift;
    return $c->stash('module')->can('post_config') ? $c->stash('module')->post_config($c) : $c->render(json => { success     => \1 });
}

sub util {
    my $c = shift;
    return $c->stash('module')->can('util') ? $c->stash('module')->util($c) : $c->render(json => { success => \1 });
}

1;

__END__

