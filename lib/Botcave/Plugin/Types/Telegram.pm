package Botcave::Plugin::Types::Telegram;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw(data_section);
use Mojo::JSON qw(from_json);
use constant {
    TRUE    => Mojo::JSON::true,
    FALSE   => Mojo::JSON::false
};

has ['app', 'storage'];

$Botcave::Plugin::Types::Telegram::ops = {
    #    {
    #        name        => 'exists',
    #        type        => 'novalue',
    #        type        => 'radio',
    #        options     => ['Yes', 'No'],
    #        translate   => 1,
    #        label       => 'Choice',
    #    }
    equal   => sub {
        my ($node) = @_;
        if ($node->{type} eq 'Enum') {
            return {
                name    => 'equal',
                type    => 'multiselect',
                label   => 'Values',
                options => $node->{enum},
            };
        }
        else {
            return {
                name        => 'equal',
                type        => 'text',
                label       => 'Values',
                multiple    => TRUE,
            };
        }
    },
    exists  => sub {
        return {
            name        => 'exists',
            type        => 'novalue',
            translate   => 1,
        };
    },
    less    => sub {
        return {
            name    => '<',
            type    => 'text',
            label   => 'Value',
        };
    },
    greater => sub {
        return {
            name    => '>',
            type    => 'text',
            label   => 'Value',
        };
    },
    match   => sub {
        return {
            name        => 'match',
            type        => 'text',
            label       => 'Values',
            multiple    => TRUE,
        };
    },
};

sub register {
    my ($self, $app, $conf) = @_;

    $self->app($app);

    # init storage with DATA
    my $data = data_section ref $self;
    map { $data->{$_} = from_json $data->{$_} } keys %$data if ref($data) eq 'HASH';
    # build references and structures in types
    if (ref($data->{types}) eq 'HASH') {
        my $types = $data->{types};
        for my $t (keys %$types) {
            if (ref($types->{$t}) eq 'HASH') {
                my $fields = $types->{$t};
                for my $f (keys %$fields) {
                    my $field = {name => $f};
                    $field->{array} = TRUE if $fields->{$f} =~ /\[.+\]/;
                    if ($fields->{$f} =~ /\((.+)\)/ && exists($data->{enums}{$1})) {
                        $field->{enum} = $data->{enums}{$1};
                        $field->{type} = 'Enum';
                    }
                    if ($fields->{$f} =~ /{(.+)}/ && exists($data->{types}{$1})) {
                        $field->{fields} = $data->{types}{$1};
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
            if ($t =~ /^-/) {
                $types->{$t} = {
                    fields  => $types->{$t},
                    name    => $t,
                    complex => TRUE,
                };
            }
        }
    }

    $self->storage($data);

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

sub operations {
    my ($self, $path) = @_;
    my $node = $self->node($path);
    if ((ref($node) eq 'HASH') && exists($node->{type})) {
        return [ map { {
            id => $_,
            %{ $Botcave::Plugin::Types::Telegram::ops->{$_}->($node) || {} }
        } } @{ $self->storage->{operations}{$node->{type}} } ];
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
        && exists($self->storage->{operations}{ $node->{type} })
    ) {
        for my $op (@{ $self->storage->{operations}{ $node->{type} } }) {
            next if $op ne $opname;
            return {
                id => $op,
                %{ $Botcave::Plugin::Types::Telegram::ops->{$op}->($node) || {} }
            } if exists $Botcave::Plugin::Types::Telegram::ops->{ $op };
        }
    }
    return undef;
}

1;

__DATA__

@@ types

{
    "-update": {
        "update": "{Update}"
    },
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
    "Boolean":            ["exists", "equal"],
    "Enum":               ["exists", "equal"],
    "Float":              ["exists", "equal", "less", "greater"],
    "Integer":            ["exists", "equal", "less", "greater"],
    "String":             ["exists", "equal", "match"],
    "Animation":          ["exists"],
    "Audio":              ["exists"],
    "CallbackQuery":      ["exists"],
    "Chat":               ["exists"],
    "ChatPhoto":          ["exists"],
    "ChosenInlineResult": ["exists"],
    "Contact":            ["exists"],
    "Document":           ["exists"],
    "Game":               ["exists"],
    "InlineQuery":        ["exists"],
    "Invoice":            ["exists"],
    "Location":           ["exists"],
    "MaskPosition":       ["exists"],
    "MessageEntity":      ["exists"],
    "Message":            ["exists"],
    "OrderInfo":          ["exists"],
    "PhotoSize":          ["exists"],
    "PreCheckoutQuery":   ["exists"],
    "ShippingQuery":      ["exists"],
    "ShippingAddress":    ["exists"],
    "Sticker":            ["exists"],
    "SuccessfulPayment":  ["exists"],
    "Venue":              ["exists"],
    "VideoNote":          ["exists"],
    "Video":              ["exists"],
    "Voice":              ["exists"],
    "Update":             ["exists"],
    "User":               ["exists"]
}
