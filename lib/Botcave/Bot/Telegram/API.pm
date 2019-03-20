package Botcave::Bot::Telegram::API;

use Mojo::Base -base;
use Carp 'croak';
use Mojo::JSON qw(encode_json);
use Mojo::UserAgent;
use Data::Dumper;

has 'token';
has 'url'   => "https://api.telegram.org/bot%s/%s";
has 'agent' => sub { Mojo::UserAgent->new };
has 'error';

sub DESTROY {}

sub AUTOLOAD {
    our $AUTOLOAD;
    (my $method = $AUTOLOAD) =~ s/.*:://; # removes the package name at the beginning
    $_[0]->api_request($method, @_);
}

sub api_request {
    my ($self, $method) = splice @_, 0, 2;
    my ($postdata, $async_cb);
    for my $arg (@_) {
        for (ref $arg) {
            ($async_cb = $arg, last) if $_ eq "CODE";
            ($postdata = $arg, last) if $_ eq "HASH";
        }
        last if defined $async_cb and defined $postdata;
    }

    my @request;
    push @request, sprintf($self->url, $self->token, $method);

    if (defined $postdata) {
        # POST arguments which are array/hash references need to be handled as follows:
        # - if no file upload exists, use application/json and encode everything with JSON::MaybeXS
        #   or let Mojo::UserAgent handle everything, when available.
        # - whenever a file upload exists, the MIME type is switched to multipart/form-data.
        #   Other refs which are not file uploads are then encoded with JSON::MaybeXS.
        my @fixable_keys;
        my $has_file_upload;
        # Traverse the post arguments.
        for my $k (keys %$postdata) {
            next unless my $ref = ref $postdata->{$k};
            # Process file uploads.
            if ($ref eq "HASH" and (exists $postdata->{$k}{file} or exists $postdata->{$k}{content})) {
                ++$has_file_upload;
            }
            elsif ($ref eq "ARRAY" and $method eq 'sendMediaGroup' and $k eq 'media') {
                for (@{$postdata->{$k}}) {
                    if (ref $_->{media} eq 'HASH' and (exists $_->{media}{file} or exists $_->{media}{content})) {
                        ++$has_file_upload;
                        # new field for media with copy
                        $postdata->{'upload_' . $has_file_upload} = { %{$_->{media}} };
                        # replace media with link to new created attachment
                        $_->{media} = 'attach://upload_' . $has_file_upload;
                    }
                }
                $postdata->{$k} = encode_json $postdata->{$k};
            }
            else {
                $postdata->{$k} = encode_json $postdata->{$k}, next if $has_file_upload;
                push @fixable_keys, $k;
            }
        }
        if ($has_file_upload) {
            # Fix keys found before the file upload.
            $postdata->{$_} = encode_json $postdata->{$_} for @fixable_keys;
            push @request, form => $postdata;
        }
        else {
            push @request, json => $postdata;
        }

    }

    push @request, $async_cb if $async_cb;

    # Perform the request.
    my $tx = $self->agent->post(@request);
    
    # We're done if the request is asynchronous.
    return $tx if $async_cb;

    # Pre-decode the response to provide, if possible, an error message.
    my $response = $tx->res->json;
    unless ($tx->success && $response && $response->{ok}) {
        $response ||= {};
        $self->error(
            ($response->{error_code} ? $response->{error_code} . " " : "") .
            ($response->{description} ? $response->{description} : ($tx->error || {})->{message} || "error")
        );
        return undef;
    }

    $response;
}

1;
