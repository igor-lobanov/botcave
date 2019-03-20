package Botcave::Util;

use Exporter 'import';

@EXPORT_OK = qw(
    optional
    args
);

sub optional { my %hash = @_; map { defined $hash{$_} ? ($_ => $hash{$_}) : () } keys %hash }
sub args { my $args = @_==1 ? $_[0] : {@_}; wantarray ? %$args : $args }

1;

