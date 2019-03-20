package Botcave::Bot::Telegram::Types;

use Mojo::Base -base;
use Mojo::JSON;
use constant {
    TRUE    => Mojo::JSON::true,
    FALSE   => Mojo::JSON::false,
};

has ['app', 'storage'];

my $TG_TYPES = {
    "-update" => "{Update}",

    "Animation" => {
        "file_id"   => "String",
        "thumb"     => "{PhotoSize}",
        "file_name" => "String",
        "mime_type" => "String",
        "file_size" => "Integer"
    },

    "Audio" => {
        "file_id"   => "String",
        "duration"  => "Integer",
        "performer" => "String",
        "title"     => "String",
        "mime_type" => "String",
        "file_size" => "Integer"
    },

    "CallbackQuery" => {
        "id"                => "Integer",
        "from"              => "{User}",
        "message"           => "{Message}",
        "inline_message_id" => "String",
        "chat_instance"     => "String",
        "data"              => "String",
        "game_short_name"   => "String"
    },

    "Chat" => {
        "id"                                => "Integer",
        "type"                              => "(EnumChatType)",
        "title"                             => "String",
        "username"                          => "String",
        "first_name"                        => "String",
        "last_name"                         => "String",
        "all_members_are_administrators"    => "Boolean",
        "photo"                             => "{ChatPhoto}",
        "description"                       => "String",
        "invite_link"                       => "String",
        "pinned_message"                    => "{Message}",
        "sticker_set_name"                  => "String",
        "can_set_sticker_set"               => "Boolean"
    },

    "ChatPhoto" => {
        "small_file_id" => "String",
        "big_file_id"   => "String"
    },

    "ChosenInlineResult" => {
        "result_id"         => "String",
        "from"              => "{User}",
        "location"          => "{Location}",
        "inline_message_id" => "String",
        "query"             => "String"
    },

    "Contact" => {
        "phone_number"  => "String",
        "first_name"    => "String",
        "last_name"     => "String",
        "user_id"       => "Integer"
    },

    "Document" => {
        "file_id"   => "String",
        "thumb"     => "{PhotoSize}",
        "file_name" => "String",
        "mime_type" => "String",
        "file_size" => "Integer"
    },

    "Game" => {
        "title"         => "String",
        "description"   => "String",
        "photo"         => "[{PhotoSize}]",
        "text"          => "String",
        "text_entities" => "[{MessageEntity}]",
        "animation"     => "{Animation}"
    },

    "InlineQuery" => {
        "id"            => "String",
        "from"          => "{User}",
        "location"      => "{Location}",
        "query"         => "String",
        "offset"        => "String"
    },

    "Invoice" => {
        "title"             => "String",
        "description"       => "String",
        "start_parameter"   => "String",
        "currency"          => "(EnumCurrency)",
        "total_amount"      => "Integer"
    },

    "Location" => {
        "longitude" => "Float",
        "latitude"  => "Float"
    },

    "MaskPosition" => {
        "point"     => "(EnumMaskPosition)",
        "x_shift"   => "Float",
        "y_shift"   => "Float",
        "scale"     => "Float"
    },

    "MessageEntity" => {
        "type"      => "(EnumMessageEntity)",
        "offset"    => "Integer",
        "length"    => "Integer",
        "url"       => "String",
        "user"      => "{User}"
    },

    "Message" => {
        "message_id"                => "Integer",
        "from"                      => "{User}",
        "date"                      => "Integer",
        "chat"                      => "{Chat}",
        "forward_from"              => "{User}",
        "forward_from_chat"         => "{Chat}",
        "forward_from_message_id"   => "Integer",
        "forward_signature"         => "String",
        "forward_date"              => "Integer",
        "reply_to_message"          => "{Message}",
        "edit_date"                 => "Integer",
        "media_group_id"            => "String",
        "author_signature"          => "String",
        "text"                      => "String",
        "entities"                  => "[{MessageEntity}]",
        "caption_entities"          => "[{MessageEntity}]",
        "audio"                     => "{Audio}",
        "document"                  => "{Document}",
        "game"                      => "{Game}",
        "photo"                     => "[{PhotoSize}]",
        "sticker"                   => "{Sticker}",
        "video"                     => "{Video}",
        "voice"                     => "{Voice}",
        "video_note"                => "{VideoNote}",
        "caption"                   => "String",
        "contact"                   => "{Contact}",
        "location"                  => "{Location}",
        "venue"                     => "{Venue}",
        "new_chat_members"          => "[{User}]",
        "left_chat_member"          => "{User}",
        "new_chat_title"            => "String",
        "new_chat_photo"            => "[{PhotoSize}]",
        "delete_chat_photo"         => "Boolean",
        "group_chat_created"        => "Boolean",
        "supergroup_chat_created"   => "Boolean",
        "channel_chat_created"      => "Boolean",
        "migrate_to_chat_id"        => "Integer",
        "migrate_from_chat_id"      => "Integer",
        "pinned_message"            => "{Message}",
        "invoice"                   => "{Invoice}",
        "successful_payment"        => "{SuccessfulPayment}"
    },

    "OrderInfo" => {
        "name"              => "String",
        "phone_number"      => "String",
        "email"             => "String",
        "shipping_address"  => "{ShippingAddress}"
    },

    "PhotoSize" => {
        "file_id"   => "String",
        "width"     => "Integer",
        "height"    => "Integer",
        "file_size" => "Integer"
    },

    "PreCheckoutQuery" => {
        "id"                    => "String",
        "from"                  => "{User}",
        "currency"              => "(EnumCurrency)",
        "total_amount"          => "Integer",
        "invoice_payload"       => "String",
        "shipping_option_id"    => "String",
        "order_info"            => "{OrderInfo}"
    },

    "ShippingQuery" => {
        "id"                => "String",
        "from"              => "{User}",
        "invoice_payload"   => "String",
        "shipping_address"  => "{ShippingAddress}"
    },

    "ShippingAddress" => {
        "country_code"      => "(EnumCountry)",
        "state"             => "String",
        "city"              => "String",
        "street_line1"      => "String",
        "street_line2"      => "String",
        "post_code"         => "String"
    },

    "Sticker" => {
        "file_id"       => "String",
        "width"         => "Integer",
        "height"        => "Integer",
        "thumb"         => "{PhotoSize}",
        "emoji"         => "String",
        "set_name"      => "String",
        "mask_position" => "{MaskPosition}",
        "file_size"     => "Integer"
    },

    "SuccessfulPayment" => {
        "currency" => "(Currency)",
        "total_amount"                  => "Integer",
        "invoice_payload"               => "String",
        "shipping_option_id"            => "String",
        "order_info"                    => "{OrderInfo}",
        "telegram_payment_charge_id"    => "String",
        "provider_payment_charge_id"    => "String"
    },

    "Venue" => {
        "location"      => "{Location}",
        "title"         => "String",
        "address"       => "String",
        "foursquare_id" => "String"
    },

    "VideoNote" => {
        "file_id"   => "String",
        "length"    => "Integer",
        "duration"  => "Integer",
        "thumb"     => "{PhotoSize}",
        "file_size" => "Integer"
    },

    "Video" => {
        "file_id"   => "String",
        "width"     => "Integer",
        "height"    => "Integer",
        "duration"  => "Integer",
        "thumb"     => "{PhotoSize}",
        "mime_type" => "String",
        "file_size" => "Integer"
    },

    "Voice" => {
        "file_id"   => "String",
        "duration"  => "Integer",
        "mime_type" => "String",
        "file_size" => "Integer"
    },

    "Update" => {
        "update_id"             => "Integer",
        "message"               => "{Message}",
        "edited_message"        => "{Message}",
        "channel_post"          => "{Message}",
        "edited_channel_post"   => "{Message}",
        "inline_query"          => "{InlineQuery}",
        "chosen_inline_result"  => "{ChosenInlineResult}",
        "callback_query"        => "{CallbackQuery}",
        "shipping_query"        => "{ShippingQuery}",
        "pre_checkout_query"    => "{PreCheckoutQuery}"
    },
    "User" => {
        "id"            => "Integer",
        "is_bot"        => "Boolean",
        "first_name"    => "String",
        "last_name"     => "String",
        "username"      => "String",
        "language_code" => "String"
    }
};

my $TG_ENUMS = {
    EnumChatType => [qw(
        private
        group
        supergroup
        channel
    )],
    EnumCountry => [qw(
        AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ
        BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ
        CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ
        DE DJ DK DM DO DZ
        EC EE EG EH ER ES ET EU
        FI FJ FK FM FO FR
        GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY
        HK HM HN HR HT HU
        ID IE IL IM IN IO IQ IR IS IT
        JE JM JO JP
        KE KG KH KI KM KN KP KR KW KY KZ
        LA LB LC LI LK LR LS LT LU LV LY
        MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ
        NA NC NE NF NG NI NL NO NP NR NU NZ
        OM
        PA PE PF PG PH PK PL PM PN PR PS PT PW PY
        QA
        RE RO RS RU RW
        SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SU SV SX SY SZ
        TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ
        UA UG UM US UY UZ
        VA VC VE VG VI VN VU
        WF WS
        YE YT
        ZA ZM ZW 
    )],
    EnumCurrency => [qw(
        AED AFN ALL AMD ARS AUD AZN
        BAM BDT BGN BND BOB BRL
        CAD CHF CLP CNY COP CRC CZK
        DKK DOP DZD
        EGP EUR
        GBP GEL GTQ
        HKD HNL HRK HUF
        IDR ILS INR ISK
        JMD JPY
        KES KGS KRW KZT
        LBP LKR
        MAD MDL MNT MUR MVR MXN MYR MZN
        NGN NIO NOK NPR NZD
        PAB PEN PHP PKR PLN PYG
        QAR
        RON RSD RUB
        SAR SEK SGD
        THB TJS TRY TTD TWD TZS
        UAH UGX USD UYU UZS
        VND
        YER
        ZAR
    )],
    EnumMaskPosition => [qw(
        forehead
        eyes
        mouth
        chin
    )],
    EnumMessageEntity => [qw(
        mention
        hashtag
        bot_command
        url
        email
        bold
        italic
        code
        pre
        text_link
        text_mention
    )]
};

my $TG_TYPES_OPERATIONS = {
    Boolean             => ["Exists", "BooleanEqual"],
    EnumChatType        => ["Exists", "EnumChatTypeEqual"],
    EnumCountry         => ["Exists", "EnumCountryEqual"],
    EnumCurrency        => ["Exists", "EnumCurrencyEqual"],
    EnumMaskPosition    => ["Exists", "EnumMaskPositionEqual"],
    EnumMessageEntity   => ["Exists", "EnumMessageEntityEqual"],
    Float               => ["Exists", "FloatEqual", "FloatLess", "FloatGreater"],
    Integer             => ["Exists", "IntegerEqual", "IntegerLess", "IntegerGreater"],
    String              => ["Exists", "StringEqual", "StringMatch"],
    Animation           => ["Exists"],
    Audio               => ["Exists"],
    CallbackQuery       => ["Exists"],
    Chat                => ["Exists"],
    ChatPhoto           => ["Exists"],
    ChosenInlineResult  => ["Exists"],
    Contact             => ["Exists"],
    Document            => ["Exists"],
    Game                => ["Exists"],
    InlineQuery         => ["Exists"],
    Invoice             => ["Exists"],
    Location            => ["Exists"],
    MaskPosition        => ["Exists"],
    MessageEntity       => ["Exists"],
    Message             => ["Exists"],
    OrderInfo           => ["Exists"],
    PhotoSize           => ["Exists"],
    PreCheckoutQuery    => ["Exists"],
    ShippingQuery       => ["Exists"],
    ShippingAddress     => ["Exists"],
    Sticker             => ["Exists"],
    SuccessfulPayment   => ["Exists"],
    Venue               => ["Exists"],
    VideoNote           => ["Exists"],
    Video               => ["Exists"],
    Voice               => ["Exists"],
    Update              => ["Exists"],
    User                => ["Exists"]
};

my $TG_OPERATIONS = {
    Exists => {
        name        => 'exists',
        type        => 'novalue',
        translate   => 1,
        exec    => sub { ~~@_ },
    },
    BooleanEqual => {
        name        => 'is',
        type        => 'radio',
        label       => 'Choice',
        translate   => 1,
        options     => ['true', 'false'],
        exec        => sub { $_[0] eq $_[1] },
    },
    EnumChatTypeEqual => {
        name    => 'equal',
        type    => 'multiselect',
        label   => 'Values',
        options => $TG_ENUMS->{EnumChatType},
        exec    => sub { $_[0] eq $_[1] },
    },
    EnumCountryEqual => {
        name    => 'equal',
        type    => 'multiselect',
        label   => 'Values',
        options => $TG_ENUMS->{EnumCountry},
        exec    => sub { $_[0] eq $_[1] },
    },
    EnumCurrencyEqual => {
        name    => 'equal',
        type    => 'multiselect',
        label   => 'Values',
        options => $TG_ENUMS->{EnumCurrency},
        exec    => sub { $_[0] eq $_[1] },
    },
    EnumMaskPositionEqual => {
        name    => 'equal',
        type    => 'multiselect',
        label   => 'Values',
        options => $TG_ENUMS->{EnumMaskPosition},
        exec    => sub { $_[0] eq $_[1] },
    },
    EnumMessageEntityEqual => {
        name    => 'equal',
        type    => 'multiselect',
        label   => 'Values',
        options => $TG_ENUMS->{EnumMessageEntity},
        exec    => sub { $_[0] eq $_[1] },
    },
    FloatEqual => {
        name        => '=',
        type        => 'text',
        multiple    => TRUE,
        label       => 'Values',
        exec        => sub { $_[0] == $_[1] },
    },
    IntegerEqual => {
        name        => '=',
        type        => 'text',
        multiple    => TRUE,
        label       => 'Values',
        exec        => sub { $_[0] == $_[1] },
    },
    StringEqual => {
        name        => 'equal',
        type        => 'text',
        label       => 'Values',
        multiple    => TRUE,
        exec        => sub { $_[0] eq $_[1] },
    },
    IntegerLess => {
        name    => '<',
        type    => 'text',
        label   => 'Value',
        exec    => sub { $_[0] < $_[1] },
    },
    FloatLess => {
        name    => '<',
        type    => 'text',
        label   => 'Value',
        exec    => sub { $_[0] < $_[1] },
    },
    FloatGreater => {
        name    => '>',
        type    => 'text',
        label   => 'Value',
        exec    => sub { $_[0] > $_[1] },
    },
    IntegerGreater => {
        name    => '>',
        type    => 'text',
        label   => 'Value',
        exec    => sub { $_[0] > $_[1] },
    },
    StringMatch => {
        name        => 'match',
        type        => 'text',
        label       => 'Values',
        multiple    => TRUE,
        exec        => sub { $_[0] =~ /$_[1]/ },
    },
};

my $singleton;

sub new {
    $singleton = shift->SUPER::new(@_) if !$singleton;
    $singleton->init(@_);
    $singleton;
}

sub init {
    my ($self) = @_;

    # build references and structures
    for my $t (keys %$TG_TYPES) {
        if (ref($TG_TYPES->{$t}) eq 'HASH') {
            my $fields = $TG_TYPES->{$t};
            for my $f (keys %$fields) {
                my $field = {name => $f};
                $field->{array} = TRUE if $fields->{$f} =~ /\[.+\]/;
                if ($fields->{$f} =~ /\((.+)\)/) {
                    $field->{type} = $1;
                    $field->{enum} = $TG_ENUMS->{$1};
                }
                if ($fields->{$f} =~ /{(.+)}/) {
                    $field->{fields} = $TG_TYPES->{$1};
                    $field->{type} = $1;
                    $field->{complex} = TRUE;
                }
                else {
                    $field->{complex} = FALSE;
                }
                ($field->{type}) = ($fields->{$f} =~ /^\[?{?(.+)}?\]?$/) if !$field->{type};
                $fields->{$f} = $field;
            }
        }
        elsif ($t =~ /^-/) {
            if ($TG_TYPES->{$t} =~ /{(.+)}/) {
                $TG_TYPES->{$t} = {
                    type    => $1,
                    fields  => $TG_TYPES->{$1},
                    complex => TRUE,
                };
            }
        }
    }

    # init storage
    $self->storage({
        types               => $TG_TYPES,
        enums               => $TG_ENUMS,
        types_operations    => $TG_TYPES_OPERATIONS,
        operations          => $TG_OPERATIONS,
    });

    # helper
    $self->app->helper(tg_types => sub { $self });

    $self;
}

sub node {
    my ($self, $path) = @_;
    my $data = $self->find_node($self->storage->{types}, split(/\./, $path));
    return undef if !defined $data;
    $data->{path} = $path;
    map { $data->{fields}{$_}{path} = $path . '.' . $data->{fields}{$_}{name} } keys %{ $data->{fields} } if exists $data->{fields};
    return $data;
}

sub find_node {
    my ($self, $node, @path) = @_;
    if (my $f = shift @path) {
        if (exists($node->{fields}{$f})) {
            $node = $node->{fields}{$f};
        }
        elsif (exists($node->{$f})) {
            $node = $node->{$f};
        }
        else {
            return undef;
        }
    }
    if (@path) {
        return $self->find_node($node, @path);
    }
    else {
        my $retval = {};
        map { $retval->{$_} = $node->{$_} if exists $node->{$_} } qw(name type complex array enum);
        if (exists($node->{fields})) {
            $retval->{fields} = {};
            for my $f (keys %{ $node->{fields} }) {
                $retval->{fields}{$f} = {};
                map { $retval->{fields}{$f}{$_} = $node->{fields}{$f}{$_} if exists $node->{fields}{$f}{$_} } qw(name type complex array enum);
            }
        }
        return $retval;
    }
}

=item operation_definition

    my $operation = $c->app->tg_types->operation_definition('StringEqual');
    # equal
    say $operation->{name};
    # IntegerEqual
    say $operation->{id};
    # 0
    say $operation->{exec}->('PayloadValue', 'ComparisionSample');
    # 1
    say $operation->{exec}->('Foo', 'Foo');

=cut

sub operation_definition {
    my ($self, $op) = @_;
    return {
        id => $op,
        %{ $self->storage->{operations}{$op} || {} }
    };
}

sub operations {
    my ($self, $path) = @_;
    my $node = $self->node($path);
    if ((ref($node) eq 'HASH') && exists($node->{type})) {
        return [ map { {
            id => $_,
            %{ $self->storage->{operations}{$_}->() || {} }
        } } @{ $self->storage->{types_operations}{$node->{type}} } ];
    }
    else {
        return [];
    }
}

sub operation {
    my ($self, $opname, $path) = @_;
    my $node = $self->node($path);
    if (
        (ref($node) eq 'HASH')
        && exists($node->{type})
        && exists($self->storage->{types_operations}{ $node->{type} })
    ) {
        for my $op (@{ $self->storage->{types_operations}{ $node->{type} } }) {
            next if $op ne $opname;
            return {
                id => $op,
                %{ $self->storage->{operations}{$op}->() || {} }
            } if exists $self->storage->{operations}{$op};
        }
    }
    return undef;
}

1;

__DATA__

@@ types

{
    "-update": "{Update}",
    "Animation": {
        "file_id":   "String",
        "thumb":     "{PhotoSize}",
        "file_name": "String",
        "mime_type": "String",
        "file_size": "Integer"
    },
    "Audio": {
        "file_id":   "String",
        "duration":  "Integer",
        "performer": "String",
        "title":     "String",
        "mime_type": "String",
        "file_size": "Integer"
    },
    "CallbackQuery": {
        "id":                "Integer",
        "from":              "{User}",
        "message":           "{Message}",
        "inline_message_id": "String",
        "chat_instance":     "String",
        "data":              "String",
        "game_short_name":   "String"
    },
    "Chat": {
        "id":                             "Integer",
        "type":                           "(ChatType)",
        "title":                          "String",
        "username":                       "String",
        "first_name":                     "String",
        "last_name":                      "String",
        "all_members_are_administrators": "Boolean",
        "photo":                          "{ChatPhoto}",
        "description":                    "String",
        "invite_link":                    "String",
        "pinned_message":                 "{Message}",
        "sticker_set_name":               "String",
        "can_set_sticker_set":            "Boolean"
    },
    "ChatPhoto": {
        "small_file_id": "String",
        "big_file_id":   "String"
    },
    "ChosenInlineResult": {
        "result_id":         "String",
        "from":              "{User}",
        "location":          "{Location}",
        "inline_message_id": "String",
        "query":             "String"
    },
    "Contact": {
        "phone_number": "String",
        "first_name":   "String",
        "last_name":    "String",
        "user_id":      "Integer"
    },
    "Document": {
        "file_id":   "String",
        "thumb":     "{PhotoSize}",
        "file_name": "String",
        "mime_type": "String",
        "file_size": "Integer"
    },
    "Game": {
        "title":         "String",
        "description":   "String",
        "photo":         "[{PhotoSize}]",
        "text":          "String",
        "text_entities": "[{MessageEntity}]",
        "animation":     "{Animation}"
    },
    "InlineQuery": {
        "id":       "String",
        "from":     "{User}",
        "location": "{Location}",
        "query":    "String",
        "offset":   "String"
    },
    "Invoice": {
        "title":           "String",
        "description":     "String",
        "start_parameter": "String",
        "currency":        "(Currency)",
        "total_amount":    "Integer"
    },
    "Location": {
        "longitude": "Float",
        "latitude":  "Float"
    },
    "MaskPosition": {
        "point": "(MaskPosition)",
        "x_shift": "Float",
        "y_shift": "Float",
        "scale": "Float"
    },
    "MessageEntity": {
        "type": "(MessageEntity)",
        "offset": "Integer",
        "length": "Integer",
        "url": "String",
        "user": "{User}"
    },
    "Message": {
        "message_id":              "Integer",
        "from":                    "{User}",
        "date":                    "Integer",
        "chat":                    "{Chat}",
        "forward_from":            "{User}",
        "forward_from_chat":       "{Chat}",
        "forward_from_message_id": "Integer",
        "forward_signature":       "String",
        "forward_date":            "Integer",
        "reply_to_message":        "{Message}",
        "edit_date":               "Integer",
        "media_group_id":          "String",
        "author_signature":        "String",
        "text":                    "String",
        "entities":                "[{MessageEntity}]",
        "caption_entities":        "[{MessageEntity}]",
        "audio":                   "{Audio}",
        "document":                "{Document}",
        "game":                    "{Game}",
        "photo":                   "[{PhotoSize}]",
        "sticker":                 "{Sticker}",
        "video":                   "{Video}",
        "voice":                   "{Voice}",
        "video_note":              "{VideoNote}",
        "caption":                 "String",
        "contact":                 "{Contact}",
        "location":                "{Location}",
        "venue":                   "{Venue}",
        "new_chat_members":        "[{User}]",
        "left_chat_member":        "{User}",
        "new_chat_title":          "String",
        "new_chat_photo":          "[{PhotoSize}]",
        "delete_chat_photo":       "Boolean",
        "group_chat_created":      "Boolean",
        "supergroup_chat_created": "Boolean",
        "channel_chat_created":    "Boolean",
        "migrate_to_chat_id":      "Integer",
        "migrate_from_chat_id":    "Integer",
        "pinned_message":          "{Message}",
        "invoice":                 "{Invoice}",
        "successful_payment":      "{SuccessfulPayment}"
    },
    "OrderInfo": {
        "name":             "String",
        "phone_number":     "String",
        "email":            "String",
        "shipping_address": "{ShippingAddress}"
    },
    "PhotoSize": {
        "file_id":   "String",
        "width":     "Integer",
        "height":    "Integer",
        "file_size": "Integer"
    },
    "PreCheckoutQuery": {
            "id":                 "String",
            "from":               "{User}",
            "currency":           "(Currency)",
            "total_amount":       "Integer",
            "invoice_payload":    "String",
            "shipping_option_id": "String",
            "order_info":         "{OrderInfo}"
    },
    "ShippingQuery": {
        "id":               "String",
        "from":             "{User}",
        "invoice_payload":  "String",
        "shipping_address": "{ShippingAddress}"
    },
    "ShippingAddress": {
        "country_code": "(Country)",
        "state":        "String",
        "city":         "String",
        "street_line1": "String",
        "street_line2": "String",
        "post_code":    "String"
    },
    "Sticker": {
        "file_id":       "String",
        "width":         "Integer",
        "height":        "Integer",
        "thumb":         "{PhotoSize}",
        "emoji":         "String",
        "set_name":      "String",
        "mask_position": "{MaskPosition}",
        "file_size":     "Integer"
    },
    "SuccessfulPayment": {
        "currency":                   "(Currency)",
        "total_amount":               "Integer",
        "invoice_payload":            "String",
        "shipping_option_id":         "String",
        "order_info":                 "{OrderInfo}",
        "telegram_payment_charge_id": "String",
        "provider_payment_charge_id": "String"
    },
    "Venue": {
        "location":      "{Location}",
        "title":         "String",
        "address":       "String",
        "foursquare_id": "String"
    },
    "VideoNote": {
        "file_id":   "String",
        "length":    "Integer",
        "duration":  "Integer",
        "thumb":     "{PhotoSize}",
        "file_size": "Integer"
    },
    "Video": {
        "file_id":   "String",
        "width":     "Integer",
        "height":    "Integer",
        "duration":  "Integer",
        "thumb":     "{PhotoSize}",
        "mime_type": "String",
        "file_size": "Integer"
    },
    "Voice": {
        "file_id":   "String",
        "duration":  "Integer",
        "mime_type": "String",
        "file_size": "Integer"
    },
    "Update": {
        "update_id":            "Integer",
        "message":              "{Message}",
        "edited_message":       "{Message}",
        "channel_post":         "{Message}",
        "edited_channel_post":  "{Message}",
        "inline_query":         "{InlineQuery}",
        "chosen_inline_result": "{ChosenInlineResult}",
        "callback_query":       "{CallbackQuery}",
        "shipping_query":       "{ShippingQuery}",
        "pre_checkout_query":   "{PreCheckoutQuery}"
    },
    "User": {
        "id":            "Integer",
        "is_bot":        "Boolean",
        "first_name":    "String",
        "last_name":     "String",
        "username":      "String",
        "language_code": "String"
    }
}

@@ enums
{
    "ChatType": [
        "private",
        "group",
        "supergroup",
        "channel"
    ],
    "Country": [
        "AD", "AE", "AF", "AG", "AI", "AL", "AM", "AO", "AQ", "AR", "AS", "AT",
        "AU", "AW", "AX", "AZ",
        "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BL", "BM", "BN",
        "BO", "BQ", "BR", "BS", "BT", "BV", "BW", "BY", "BZ",
        "CA", "CC", "CD", "CF", "CG", "CH", "CI", "CK", "CL", "CM", "CN", "CO",
        "CR", "CU", "CV", "CW", "CX", "CY", "CZ",
        "DE", "DJ", "DK", "DM", "DO", "DZ",
        "EC", "EE", "EG", "EH", "ER", "ES", "ET", "EU",
        "FI", "FJ", "FK", "FM", "FO", "FR",
        "GA", "GB", "GD", "GE", "GF", "GG", "GH", "GI", "GL", "GM", "GN", "GP",
        "GQ", "GR", "GS", "GT", "GU", "GW", "GY",
        "HK", "HM", "HN", "HR", "HT", "HU",
        "ID", "IE", "IL", "IM", "IN", "IO", "IQ", "IR", "IS", "IT",
        "JE", "JM", "JO", "JP",
        "KE", "KG", "KH", "KI", "KM", "KN", "KP", "KR", "KW", "KY", "KZ",
        "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "LY",
        "MA", "MC", "MD", "ME", "MF", "MG", "MH", "MK", "ML", "MM", "MN", "MO",
        "MP", "MQ", "MR", "MS", "MT", "MU", "MV", "MW", "MX", "MY", "MZ",
        "NA", "NC", "NE", "NF", "NG", "NI", "NL", "NO", "NP", "NR", "NU", "NZ",
        "OM",
        "PA", "PE", "PF", "PG", "PH", "PK", "PL", "PM", "PN", "PR", "PS", "PT",
        "PW", "PY",
        "QA",
        "RE", "RO", "RS", "RU", "RW",
        "SA", "SB", "SC", "SD", "SE", "SG", "SH", "SI", "SJ", "SK", "SL", "SM",
        "SN", "SO", "SR", "SS", "ST", "SU", "SV", "SX", "SY", "SZ",
        "TC", "TD", "TF", "TG", "TH", "TJ", "TK", "TL", "TM", "TN", "TO", "TR",
        "TT", "TV", "TW", "TZ",
        "UA", "UG", "UM", "US", "UY", "UZ",
        "VA", "VC", "VE", "VG", "VI", "VN", "VU",
        "WF", "WS",
        "YE", "YT",
        "ZA", "ZM", "ZW" 
    ],
    "Currency": [
        "AED", "AFN", "ALL", "AMD", "ARS", "AUD", "AZN",
        "BAM", "BDT", "BGN", "BND", "BOB", "BRL",
        "CAD", "CHF", "CLP", "CNY", "COP", "CRC", "CZK",
        "DKK", "DOP", "DZD",
        "EGP", "EUR",
        "GBP", "GEL", "GTQ",
        "HKD", "HNL", "HRK", "HUF",
        "IDR", "ILS", "INR", "ISK",
        "JMD", "JPY",
        "KES", "KGS", "KRW", "KZT",
        "LBP", "LKR",
        "MAD", "MDL", "MNT", "MUR", "MVR", "MXN", "MYR", "MZN",
        "NGN", "NIO", "NOK", "NPR", "NZD",
        "PAB", "PEN", "PHP", "PKR", "PLN", "PYG",
        "QAR",
        "RON", "RSD", "RUB",
        "SAR", "SEK", "SGD",
        "THB", "TJS", "TRY", "TTD", "TWD", "TZS",
        "UAH", "UGX", "USD", "UYU", "UZS",
        "VND",
        "YER",
        "ZAR"
    ],
    "MaskPosition": [
        "forehead",
        "eyes",
        "mouth",
        "chin"
    ],
    "MessageEntity": [
        "mention",
        "hashtag",
        "bot_command",
        "url",
        "email",
        "bold",
        "italic",
        "code",
        "pre",
        "text_link",
        "text_mention"
    ]
}

@@ operations

{
    "Boolean":            ["Exists", "BooleanEqual"],
    "Enum":               ["Exists", "EnumEqual"],
    "Float":              ["Exists", "FloatEqual", "FloatLess", "FloatGreater"],
    "Integer":            ["Exists", "IntegerEqual", "IntegerLess", "IntegerGreater"],
    "String":             ["Exists", "StringEqual", "StringMatch"],
    "Animation":          ["Exists"],
    "Audio":              ["Exists"],
    "CallbackQuery":      ["Exists"],
    "Chat":               ["Exists"],
    "ChatPhoto":          ["Exists"],
    "ChosenInlineResult": ["Exists"],
    "Contact":            ["Exists"],
    "Document":           ["Exists"],
    "Game":               ["Exists"],
    "InlineQuery":        ["Exists"],
    "Invoice":            ["Exists"],
    "Location":           ["Exists"],
    "MaskPosition":       ["Exists"],
    "MessageEntity":      ["Exists"],
    "Message":            ["Exists"],
    "OrderInfo":          ["Exists"],
    "PhotoSize":          ["Exists"],
    "PreCheckoutQuery":   ["Exists"],
    "ShippingQuery":      ["Exists"],
    "ShippingAddress":    ["Exists"],
    "Sticker":            ["Exists"],
    "SuccessfulPayment":  ["Exists"],
    "Venue":              ["Exists"],
    "VideoNote":          ["Exists"],
    "Video":              ["Exists"],
    "Voice":              ["Exists"],
    "Update":             ["Exists"],
    "User":               ["Exists"]
}
