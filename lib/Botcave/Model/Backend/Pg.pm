package Botcave::Model::Backend::Pg;

use Mojo::Base 'Botcave::Model::Backend';
use Mojo::Pg;
use Carp 'croak';
has 'pg';

sub new {
    my $self = shift->SUPER::new(pg => Mojo::Pg->new(@_));

    # check Pg version
    my $db = Mojo::Pg->new(@_)->db;
    croak 'PostgreSQL 9.5 or later is required' if $db->dbh->{pg_server_version} < 90500;
    $db->disconnect;

    # start migrations
    $self->pg->auto_migrate(1)->migrations->name('botcave')->from_data;

    return $self;
}

# Model::Agents
sub find_agent_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{valid} = 1 unless (exists $args->{valid});
    $self->pg->db->select('agents', '*', $args)->hash;
}

sub agent_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('agents', '*', $args)->hashes;
}

sub agent_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{type} = 'agent';
    $self->pg->db->insert('agents', $args, {returning => '*'})->hash;
}

# Model::Bots
sub find_bot_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{valid} = 1 unless (exists $args->{valid});
    my $view = $args->{-scenarios} ? 'bots_with_scenarios' : 'bots';
    my @fields = map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(id name type online valid);
    my @conf = map {
        exists $args->{"conf.$_"} ? (conf => {' ->> ' => \["'$_' = ?", $args->{"conf.$_"}]}) : ()
    } map {/^conf\.(\S+)$/} grep /^conf\.\S+$/, keys %$args;
    my @data = map {
        exists $args->{"data.$_"} ? (data => {' ->> ' => \["'$_' = ?", $args->{"data.$_"}]}) : ()
    } map {/^data\.(\S+)$/} grep /^data\.\S+$/, keys %$args;
    $self->pg->db->select($view, '*', {-and => [@fields, @conf, @data]})->expand->hash;
}

sub bot_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{valid} = 1 unless (exists $args->{valid});
    my $view = $args->{-scenarios} ? 'bots_with_scenarios' : 'bots';
    my $search = {map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(id name type online valid)};
    $self->pg->db->select($view, '*', $search, 'id')->expand->hashes;
}

sub bot_add {
    my $self = shift;
    my $args = $self->_args(@_);
    my $fields = {map {$_ => $args->{$_}} qw(name type online conf data)};
    map { $fields->{$_} = Mojo::JSON::to_json($fields->{$_}) if ref $fields->{$_} } qw(conf data);
    my $bot = eval {
        my $tx = $self->pg->db->begin;
        my $b = $self->pg->db->insert('bots', $fields, {returning => '*'})->expand->hash;
        if ($args->{scenarioid}) {
            $args->{scenarioid} = [$args->{scenarioid}] if !ref $args->{scenarioid};
            $self->pg->db->insert('bots_scenarios', {botid => $b->{id}, scenarioid => $_}) for @{ $args->{scenarioid} };
        }
        $tx->commit;
        return $b;
    };
    croak $@ if $@;
    $bot;
}

sub bot_online {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->update('bots', {online => 1}, $args);
    $self;
}

sub bot_offline {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->update('bots', {online => 0}, $args);
    $self;
}

sub bot_update {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    my $fields = {map {$_ => $args->{$_}} qw(id name online conf data)};
    map { $fields->{$_} = Mojo::JSON::to_json($fields->{$_}) if ref $fields->{$_} } qw(conf data);
    eval {
        my $tx = $self->pg->db->begin;
        $self->pg->db->update('bots', $fields, {id => $id, valid => 1});
        $self->pg->db->delete('bots_scenarios', {botid => $id});
        if ($args->{scenarioid}) {
            $args->{scenarioid} = [$args->{scenarioid}] if !ref $args->{scenarioid};
            $self->pg->db->insert('bots_scenarios', {botid => $id, scenarioid => $_}) for @{ $args->{scenarioid} };
        }
        $tx->commit;
    };
    croak $@ if $@;
    $self;
}

sub bot_unvalidate {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    $self->pg->db->update('bots', {valid => 0}, {id => $id});
    $self;
}


# Model::Updates
sub find_update_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('updates', '*', $args)->hash;
}

sub update_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{update} = Mojo::JSON::to_json($args->{update}) if ref $args->{update};
    $self->pg->db->insert('updates', $args, {returning => '*'})->expand->hash;
}

# Model::Addons
sub addons_list {
    my ($self, $where, $order) = @_;
    $self->pg->db->select('addons', '*', $where, $order)->expand->hashes;
}

sub find_addon_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('addons', '*', $args)->expand->hash;
}

sub addon_activate {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->update('addons', {active => 1}, $args);
    $self;
}

sub addon_deactivate {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->update('addons', {active => 0}, $args);
    $self;
}

sub addon_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->insert('addons', $args, {returning => '*'})->expand->hash;
}

sub addon_unvalidate {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->update('addons', {valid => 0}, $args);
}

# Model::Customers
sub customers_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('customers', '*', $args)->hashes;
}

sub find_customer_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('customers', '*', $args)->hash;
}

# Model::Filters
sub find_filter_by {
    my $self = shift;
    my $args = $self->_args(@_);
    my $fields = { map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(id name) };
    $self->pg->db->select('filters', '*', $fields)->expand->hash;
}

sub filters_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('filters', '*', {valid => 1, %$args})->hashes;
}

sub filter_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{conf} = Mojo::JSON::to_json($args->{conf}) if ref $args->{conf};
    my $fields = {map {$_ => $args->{$_}} qw(name module conf)};
    $self->pg->db->insert('filters', $args, {returning => '*'})->hash;
}

sub filter_update {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    $args->{conf} = Mojo::JSON::to_json($args->{conf}) if ref $args->{conf};
    my $fields = {map {$_ => $args->{$_}} qw(name module conf)};
    $self->pg->db->update('filters', $fields, {id => $id, valid => 1}, {returning => '*'})->hash;
}

sub filter_unvalidate {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    $self->pg->db->update('filters', {valid => 0}, {id => $id});
}

# Model::Scenarios
sub find_scenario_by {
    my $self = shift;
    my $args = $self->_args(@_);
    my $view = $args->{-episodes} ? 'scenarios_with_episodes' : 'scenarios';
    my $fields = { map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(id name) };
    $self->pg->db->select($view, '*', $fields)->expand->hash;
}

sub scenarios_list {
    my $self = shift;
    my $args = $self->_args(@_);
    my $view = $args->{-episodes} ? 'scenarios_with_episodes' : 'scenarios';
    my $fields = { map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(event) };
    $self->pg->db->select($view, '*', {valid => 1, %$fields}, 'id')->expand->hashes;
}

sub scenario_add {
    my $self = shift;
    my $args = $self->_args(@_);
    my $fields = {map {$_ => $args->{$_}} qw(name description)};
    $self->pg->db->insert('scenarios', $args, {returning => '*'})->hash;
}

sub scenario_update {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    my $fields = {map {$_ => $args->{$_}} qw(name description)};
    $self->pg->db->update('scenarios', $fields, {id => $id, valid => 1}, {returning => '*'})->hash;
}

sub scenario_unvalidate {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    $self->pg->db->update('scenarios', {valid => 0}, {id => $id});
}

# Model::Episodes
sub find_episode_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('episodes', '*', $args)->expand->hash;
}

sub episodes_list {
    my $self = shift;
    my $args = $self->_args(@_);
    my $view = $args->{-filters} ? 'episodes_with_filters' : 'episodes';
    my $fields = { map { exists $args->{$_} ? ($_ => $args->{$_}) : () } qw(scenarioid module position) };
    $self->pg->db->select($view, '*', {valid => 1, %$fields}, 'position')->expand->hashes;
}

sub episode_add {
    my $self = shift;
    my $args = $self->_args(@_);
    my $fields = {map {$_ => $args->{$_}} qw(scenarioid module description)};
    eval {
        my $tx = $self->pg->db->begin;
        my $episode = $self->pg->db->insert('episodes', $fields, {returning => '*'})->hash;
        if ($args->{filterid}) {
            $args->{filterid} = [$args->{filterid}] if !ref $args->{filterid};
            $self->pg->db->insert('episodes_filters', {episodeid => $episode->{id}, filterid => $_}) for @{ $args->{filterid} };
        }
        $tx->commit;
    };
    croak $@ if $@;
}

sub episode_update {
    my $self = shift;
    my $args = $self->_args(@_);
    my $id = $args->{id} || return $self;
    my $fields = {map {$_ => $args->{$_}} qw(scenarioid module position description)};
    $self->pg->db->update('episodes', $fields, {id => $id, valid => 1}, {returning => '*'})->hash;
}

sub episode_unvalidate {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->update('episodes', {valid => 0}, $args);
}

1;

__DATA__

@@ botcave

-- 63 up

CREATE TYPE bot_type AS ENUM ('Telegram');

CREATE TYPE user_type AS ENUM ('agent', 'system', 'customer');

CREATE TABLE users
(
  uid serial,
  type user_type NOT NULL,
  class character varying(64) NOT NULL DEFAULT ''::character varying,
  valid boolean NOT NULL DEFAULT true,
  CONSTRAINT users_pkey PRIMARY KEY (uid)
);

CREATE TABLE addons
(
  id serial,
  module character varying(255) NOT NULL,
  active boolean NOT NULL DEFAULT false,
  valid boolean NOT NULL DEFAULT true,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT addons_pkey PRIMARY KEY (id)
);

CREATE TABLE agents
(
-- Inherited from table users:  uid integer NOT NULL DEFAULT nextval('users_uid_seq'::regclass),
-- Inherited from table users:  type user_type NOT NULL DEFAULT 'agent'::user_type,
-- Inherited from table users:  class character varying(64) NOT NULL DEFAULT ''::character varying,
-- Inherited from table users:  valid boolean NOT NULL DEFAULT true,
  id serial,
  email character varying(64),
  password character varying(27),
  first_name character varying(64),
  last_name character varying(64),
  CONSTRAINT agents_pkey PRIMARY KEY (id),
  CONSTRAINT customers_type_check CHECK (type = 'agent'::user_type)
)
INHERITS (users);

CREATE TABLE bots
(
  id serial,
  name character varying(255),
  type bot_type NOT NULL DEFAULT 'Telegram'::bot_type,
  online boolean DEFAULT false,
  conf jsonb NOT NULL DEFAULT '{}'::jsonb,
  data jsonb,
  valid boolean NOT NULL DEFAULT true,
  scenarioid integer,
  CONSTRAINT bots_pkey PRIMARY KEY (id),
  CONSTRAINT bots_scenarioid_fkey FOREIGN KEY (scenarioid)
      REFERENCES scenarios (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE bots_scenarios
(
  botid integer NOT NULL,
  scenarioid integer NOT NULL,
  CONSTRAINT bots_scenarios_pkey PRIMARY KEY (botid, scenarioid),
  CONSTRAINT bots_scenarios_botid_fkey FOREIGN KEY (botid)
      REFERENCES bots (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT bots_scenarios_scenarioid_fkey FOREIGN KEY (scenarioid)
      REFERENCES scenarios (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE customers
(
-- Inherited from table users:  uid integer NOT NULL DEFAULT nextval('users_uid_seq'::regclass),
-- Inherited from table users:  type user_type NOT NULL,
-- Inherited from table users:  class character varying(64) NOT NULL DEFAULT ''::character varying,
-- Inherited from table users:  valid boolean NOT NULL DEFAULT true,
  CONSTRAINT customers_type_check CHECK (type = 'customer'::user_type)
)
INHERITS (users);

CREATE TABLE scenarios
(
  id serial NOT NULL DEFAULT nextval('scenarios_id_seq'::regclass),
  name text NOT NULL DEFAULT 'New scenario'::text,
  valid boolean NOT NULL DEFAULT true,
  description text,
  event text NOT NULL DEFAULT ''::text,
  CONSTRAINT scenarios_pkey PRIMARY KEY (id)
);

CREATE SEQUENCE episodes_position_seq
  INCREMENT 10
  MINVALUE 10
  MAXVALUE 9223372036854775807
  START 10
  CACHE 1;

CREATE TABLE episodes
(
  id serial,
  scenarioid integer NOT NULL,
  module text NOT NULL DEFAULT ''::text,
  "position" integer NOT NULL DEFAULT nextval('episodes_position_seq'::regclass),
  valid boolean NOT NULL DEFAULT true,
  description text,
  CONSTRAINT episodes_pkey PRIMARY KEY (id),
  CONSTRAINT episodes_scenarioid_fkey FOREIGN KEY (scenarioid)
      REFERENCES scenarios (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE filters
(
  id serial,
  name text,
  module text,
  conf json,
  valid boolean NOT NULL DEFAULT true,
  CONSTRAINT filters_pkey PRIMARY KEY (id)
);

CREATE TABLE episodes_filters
(
  episodeid integer NOT NULL,
  filterid integer NOT NULL,
  CONSTRAINT episodes_filters_pkey PRIMARY KEY (episodeid, filterid),
  CONSTRAINT episodes_filters_episodeid_fkey FOREIGN KEY (episodeid)
      REFERENCES episodes (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT episodes_filters_filterid_fkey FOREIGN KEY (filterid)
      REFERENCES filters (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE updates
(
  update_id bigint NOT NULL,
  bot_id bigint NOT NULL,
  update json,
  CONSTRAINT updates_pkey PRIMARY KEY (update_id),
  CONSTRAINT updates_update_id_bot_id_key UNIQUE (update_id, bot_id)
);

CREATE OR REPLACE VIEW episodes_with_filters AS 
  SELECT
    e.id,
    e.scenarioid,
    e.module,
    e."position",
    e.valid,
    e.description,
    COALESCE(json_agg(eff.*) FILTER (WHERE eff.filterid IS NOT NULL), '[]'::json) AS filters
  FROM episodes e
  LEFT JOIN (
    SELECT
      ef.episodeid,
      ef.filterid,
      f.name,
      f.module,
      f.conf
    FROM episodes_filters ef
    LEFT JOIN filters f ON ef.filterid = f.id AND f.valid
  ) eff ON e.id = eff.episodeid
  WHERE e.valid
  GROUP BY e.id;

CREATE OR REPLACE VIEW scenarios_with_episodes AS 
  SELECT
    s.id,
    s.name,
    s.valid,
    COALESCE(s.description, ''::text) AS description,
    s.event,
    COALESCE(json_agg(a.*) FILTER (WHERE a.id IS NOT NULL), '[]'::json) AS episodes
  FROM scenarios s
  LEFT JOIN (
    SELECT
      ewf.id,
      ewf.scenarioid,
      ewf.module,
      ewf."position",
      COALESCE(ewf.description, ''::text) AS description,
      ewf.filters
    FROM episodes_with_filters ewf
    ORDER BY ewf."position"
  ) a ON s.id = a.scenarioid
  GROUP BY s.id;
