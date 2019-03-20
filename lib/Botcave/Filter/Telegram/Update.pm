package Botcave::Filter::Telegram::Update;

use Mojo::Base 'Botcave::Filter';
use constant {
    TRUE    => Mojo::JSON::true,
    FALSE   => Mojo::JSON::false
};
use Carp 'croak';

use Data::Dumper;

has events => sub {{
    'Telegram::NewUpdate' => 1
}};

sub check {
    my ($self, $conf, $payload) = @_;

    if ($conf->{conditions} && @{ $conf->{conditions} }) {
        for my $condition (@{ $conf->{conditions} }) {
            my $match = 0;
            my $sign = $condition->{negation} ? sub {!$_[0]} : sub {$_[0]};
            my $fullpath = join('.', '-update', (split(/\./, $condition->{path} || '')));
            my $operation = $self->app->tg_types->operation($condition->{operation}, $fullpath);
            my @values = _find_values($condition->{path}, $payload);
            if ($operation->{type} eq 'novalue') {
                # novalue doesn't require samples but needs values
                $match = 1 if $sign->($operation->{exec}->(@values));
            }
            else {
                # check all values with all samples - single match is enough
                MATCH:
                for my $sample (@{$condition->{values} || []}) {
                    for my $value (@values) {
                        if ($sign->($operation->{exec}->($value, $sample))) {
                            $match = 1;
                            last MATCH;
                        }
                    }
                }
            }
            # any failed condition means failed check
            return 0 if !$match;
        }
    }

    # no fails - check is successful
    return 1;
}

sub _find_values {
    my ($path, $payload) = @_;
    my @path = split(/\./, $path);
    my $node = shift @path;
    my @values;
    if (exists($payload->{$node})) {
        if (ref($payload->{$node}) eq 'ARRAY') {
            push @values, _find_values(join('.', @path), $_) for @{ $payload->{$node} };
        }
        elsif (ref($payload->{$node}) eq 'HASH') {
            push @values, _find_values(join('.', @path), $payload->{$node});
        }
        else {
            push @values, $payload->{$node};
        }
    }
    return @values;
}

# controller functions

sub config {
    my ($self, $c) = @_;
    $c->render(template => 'admin/filters/config/telegram/update');
}

sub post_config {
    my ($self, $c) = @_;
    my $data = $c->req->json;


    # put single value in array always
    $data->{value} = [$data->{value}] unless ref $data->{value};
    # as far as value can be multiple and some values can be empty we just pre-filter empty ones
    $data->{value} = [ grep {$_} @{ $data->{value} } ];
    # some operations don't require values, we need this fake value to make required validation working
    # really empty values checked in custom check, required need to perform all checks (optional skips them)
    push @{$data->{value}}, \1;

    $data->{negation} = $data->{negation} ? TRUE : FALSE;

    my $lang = $c->app->lang($c->stash('lang'));

    my $id = $c->stash('id');

    # validate data
    my $validation = $c->validation;
    my $fullpath = join('.', $data->{root}, (split(/\./, $data->{path} || '')));
    $validation->validator->add_check(valid_path => sub {
        my ($validation, $topic, $value) = @_;
        return $c->tg_types->node($fullpath) ? 0 : 1;
    })->add_check(valid_operation => sub {
        my ($validation, $topic, $value) = @_;
        my $result = 1;
        for my $op (@{ $c->tg_types->operations($fullpath) || [] }) {
            if ($value eq $op->{id}) {
                $result = 0;
                last;
            }
        }
        return $result;
    })->add_check(valid_value => sub {
        my ($validation, $topic, $value) = @_;
        return 0 if ref $value; # skip fake ref valid check
        my $op = $c->tg_types->operation($data->{operation}, $fullpath);
        return 1 if !$op;
        if (
            (exists($op->{re}) && $value !~ /^$op->{re}$/)
            || (exists($op->{options}) && !grep {$value eq $_} @{$op->{options}})
        ) {
            return 1;
        }
        return 0;
    })->add_check(empty_value => sub {
        my ($validation, $topic, $value) = @_;
        my $op = $c->tg_types->operation($data->{operation}, $fullpath);
        return (!$op || (($op->{type} ne 'novalue') && @{$data->{value}}<2 )) ? 1 : 0;
    });

    $validation->input({ map { $_ => $data->{$_} } qw( path operation negation value ) });

    my (@errors, @fields);
    if ($validation->has_data) {
        $data = $validation
            ->required('path', 'trim')->valid_path
            ->required('operation', 'trim')->valid_operation
            ->required('value', 'trim')->valid_value->empty_value
            ->optional('negation')
            ->output;
        # remove fake ref value added before checks
        $data->{value} = [grep {!ref} @{$data->{value}}];
        if ($validation->has_error) {
            for (@{$validation->failed}) {
                push @errors, $lang->errors->{ join( ':', 'filter_config_telegram_update', $_, $validation->error($_)->[0] ) };
                push @fields, $_;
            }
        }
        else {
            my $filter = $c->stash('filter');
            $filter->{conf} ||= {};
            $filter->{conf}{conditions} ||= [];
            push @{$filter->{conf}{conditions}}, {
                path        => $data->{path},
                negation    => $data->{negation},
                operation   => $data->{operation},
                values      => $data->{value}
            };
            $c->model('Filters')->update($filter);
            $c->botplace->init_bots;
            return $c->render(json => {
                success     => TRUE,
                redirect    => '/admin/filter/' . $filter->{id} . '/config',
            });
        }
    }
    else {
        push @errors, $lang->errors->{'filter_config_telegram_update:nodata'};
    }

    return $c->render(json => {
        success => FALSE,
        title   => $lang->titles->{'modal:errors'},
        comment => $c->tl('Check, correct and resubmit form'),
        errors  => \@errors,
        fields  => \@fields,
    });
}

sub util {
    my ($self, $c) = @_;

    if ($c->stash('function') eq 'tree') {
        return $self->util_tree($c);
    }
    elsif ($c->stash('function') eq 'operations') {
        return $self->util_operations($c);
    }
    elsif ($c->stash('function') eq 'condition_delete') {
        return $self->util_condition_delete($c);
    }
    else {
        return $c->reply->not_found;
    }
}

sub util_tree {
    my ($self, $c) = @_;
    my $root = $c->param('root');
    my $struct = $c->tg_types->node(join('.', $root, (split(/\./, $c->param('path') || ''))));
    my @fields = map {
        my $field = $struct->{fields}{$_};
        $field->{path} =~ s/^$root\.//;
        {
            text        => $_ . ' : ' . ($field->{array} ? $c->tl('Array of') . ' ' : '') . $field->{type},
            path        => $field->{path},
            hasChildren => $field->{complex},
        }
    } sort keys %{ $struct->{fields} || {} };
    $c->render(json => \@fields);
}

sub util_operations {
    my ($self, $c) = @_;
    my $root = $c->param('root');
    my $ops = $c->tg_types->operations(join('.', $root, (split(/\./, $c->param('path'))))) || [];
    for my $op (@$ops) {
        map {$op->{$_} = $c->tl($op->{$_})} qw (name label);
        if ($op->{translate} && exists($op->{options})) {
            for my $option (@{ $op->{options} }) {
                $op->{tl}{$option} = $c->tl($option);
            }
        }
    }
    $c->render(json => $ops);
}

sub util_condition_delete {
    my ($self, $c) = @_;
    my $num = $c->param('num');

    my $filter = $c->stash('filter');
    if (
        exists($filter->{conf})
        && exists($filter->{conf}{conditions})
        && $num =~ /^\d+$/
        && @{ $filter->{conf}{conditions} } > $num
    ) {
        splice @{ $filter->{conf}{conditions} }, $num, 1;
        $c->model('Filters')->update($filter);
    }
    $c->redirect_to('/admin/filter/' . $filter->{id} . '/config');
}

1;

__END__

