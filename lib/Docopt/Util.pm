package Docopt::Util;
use strict;
use warnings;
use utf8;
use parent qw(Exporter);
use boolean;

our @EXPORT_OK = qw(repl class_name string_strip string_partition in True False is_number defined_or serialize);

sub True()  { true }
sub False() { false }

use Data::Dumper; # serializer
use Scalar::Util ();
use Storable ();

sub serialize($) {
    local $Storable::canonical=1;
    return Storable::nfreeze($_[0]);
}

sub is_number {
    my $stuff = shift;
    return 0 if ref $stuff;
    return 0 unless defined $stuff;
    return 1 if $stuff =~ /\A[0-9]+\z/;
    return 0;
}

sub in {
    my ($val, $patterns) = @_;
    for (@$patterns) {
        if (defined $_) {
            return 1 if $val eq $_;
        } else {
            return 1 if not defined $val;
        }
    }
    return 0;
}

sub repl($) {
    my ($val) = @_;
    if (Scalar::Util::blessed($val) && $val->can('__repl__')) {
        $val->__repl__;
    } elsif (ref($val) eq 'ARRAY') {
        return '[' . join(', ', map { &repl($_) } @$val) . ']';
    } else {
        local $Data::Dumper::Terse=1;
        local $Data::Dumper::Indent=0;
        Dumper($val)
    }
}

sub class_name {
    my $name = ref $_[0] || $_[0];
    $name =~ s/^Docopt:://;
    $name;
}

sub string_strip($) {
    local $_ = shift;
    s/^\s+//;
    s/\s+$//;
    $_;
}

sub string_partition($$) {
    my ($str, $sep) = @_;
    if ($str =~ /\A(.*?)$sep(.*)\z/) {
        return ($1, $sep, $2);
    } else {
        return ($str, '', '');
    }
}

sub defined_or { defined($_[0]) ? $_[0] : $_[1] }

1;

