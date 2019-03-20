package Botcave::Model::Backend::CallcenterPg;

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
    $self->pg->auto_migrate(1)->migrations->name('botcave_callcenter')->from_data;

    return $self;
}

# Model::Callcenter::Calls
sub call_entries_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('cc_entries_users', '*', $args)->expand->hashes;
}

sub calls_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('cc_calls', '*', $args)->hashes;
}

sub find_call_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $args = { map {
        if ($_ eq 'status') {
            # take status from another table through subrequest
            my ($st, @bind) = $self->pg->abstract->select('cc_call_statuses', 'id', {name => {-in => $args->{$_}}});
            'statusid' => {-in => \[$st => @bind]};
        }
        else {
            $_ => $args->{$_};
        }
    } keys %$args };
    $self->pg->db->select('cc_calls', '*', $args)->hash;
}

sub call_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->insert('cc_calls', $args, {returning => \"*, true AS new"})->hash;
}

# Model::Callcenter::Entries
sub entries_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('cc_entries', '*', $args)->expand->hashes;
}

sub entry_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{content} = Mojo::JSON::to_json($args->{content}) if ref $args->{content};
    $self->pg->db->insert('cc_entries', $args, {returning => '*'})->hash;
}

# Model::Callcenter::TelegramUsers
sub tg_users_list {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->select('cc_tg_users', '*', $args)->hashes;
}

sub tg_user_add {
    my $self = shift;
    my $args = $self->_args(@_);
    $self->pg->db->insert(
        'cc_tg_users',
        { map {$_ => $args->{$_}} qw(id is_bot first_name last_name username) },
        { returning => \"*, true AS new" })->hash;
}

sub find_tg_user_by {
    my $self = shift;
    my $args = $self->_args(@_);
    $args->{valid} = 1;
    $self->pg->db->select('cc_tg_users', '*', $args)->hash;
}

1;

__DATA__

@@ botcave_callcenter

-- 25 up
CREATE TYPE cc_entry_type AS ENUM
(
  'message',
  'edited_message',
  'channel_post',
  'edited_channel_post',
  'inline_query',
  'chosen_inline_result',
  'callback_query',
  'shipping_query',
  'pre_checkout_query'
);
CREATE TABLE cc_call_statuses
(
  id serial,
  name character varying(32),
  valid boolean DEFAULT true,
  CONSTRAINT cc_call_statuses_pkey PRIMARY KEY (id)
);
CREATE TABLE cc_calls
(
  id serial,
  statusid integer,
  chat_id bigint,
  CONSTRAINT cc_calls_pkey PRIMARY KEY (id)
);
CREATE TABLE cc_entries
(
  id integer NOT NULL DEFAULT nextval('cc_entries_id_seq'::regclass),
  callid integer NOT NULL,
  type cc_entry_type,
  content jsonb DEFAULT '{}'::jsonb,
  uid integer NOT NULL DEFAULT 0,
  CONSTRAINT cc_entries_pkey PRIMARY KEY (id)
);
CREATE TABLE cc_tg_users
(
  -- uid serial,
  -- type user_type NOT NULL,
  -- class character varying(64) NOT NULL DEFAULT ''::character varying,
  -- valid boolean NOT NULL DEFAULT true,
  id bigint NOT NULL,
  is_bot boolean NOT NULL DEFAULT false,
  first_name character varying(255) NOT NULL,
  last_name character varying(255),
  username character varying(255),
  CONSTRAINT cc_tg_users_pkey PRIMARY KEY (uid),
  CONSTRAINT cc_tg_users_class_check CHECK (class::text = 'telegram'::text),
  CONSTRAINT cc_tg_users_type_check CHECK (type = 'customer'::user_type)
)
INHERITS (customers);
ALTER TABLE cc_tg_users ALTER COLUMN type SET DEFAULT 'customer'::user_type;
ALTER TABLE cc_tg_users ALTER COLUMN class SET DEFAULT 'telegram';
CREATE UNIQUE INDEX cc_tg_users_id_key ON cc_tg_users (id) WHERE valid;
CREATE OR REPLACE VIEW cc_entries_users AS 
 SELECT en.id,
    en.callid,
    en.type,
    en.content,
    en.uid,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ag.type
            WHEN tu.type = 'customer'::user_type THEN tu.type
            ELSE 'system'::user_type
        END AS user_type,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ag.class
            WHEN tu.type = 'customer'::user_type THEN tu.class
            ELSE ''::character varying
        END AS user_class,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ag.id::bigint
            WHEN tu.type = 'customer'::user_type THEN tu.id
            ELSE 0::bigint
        END AS user_id,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ag.first_name
            WHEN tu.type = 'customer'::user_type THEN tu.first_name
            ELSE ''::character varying
        END AS first_name,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ag.last_name
            WHEN tu.type = 'customer'::user_type THEN tu.last_name
            ELSE ''::character varying
        END AS last_name,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ag.email
            WHEN tu.type = 'customer'::user_type THEN ''::character varying
            ELSE ''::character varying
        END AS email,
        CASE
            WHEN ag.type = 'agent'::user_type THEN ''::character varying
            WHEN tu.type = 'customer'::user_type THEN tu.username
            ELSE ''::character varying
        END AS username,
        CASE
            WHEN ag.type = 'agent'::user_type THEN false
            WHEN tu.type = 'customer'::user_type THEN tu.is_bot
            ELSE false
        END AS is_bot
   FROM cc_entries en
     LEFT JOIN agents ag ON en.uid = ag.uid
     LEFT JOIN cc_tg_users tu ON en.uid = tu.uid;

