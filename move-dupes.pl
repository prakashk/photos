#!/usr/bin/env perl

use v5.14;
use File::Basename qw<dirname>;

my $deleted_dir = "Z-deleted";

sub process_group {
    my ($hash, @images) = @_;
    say "# H $hash";

    # keep first image, optionally renaming
    my $first = shift @images;
    my ($old, $new) = split /(?<=G) /, $first, 2;
    if ($new) {
        say "# R\t$old\t$new";
        say "mkdir -pv '", dirname($new), "'";
        say "mv -v --no-clobber '$old' '$new'";
    }
    else {
        say "# K\t$old";
    }

    for (@images) {
        if (m|^$deleted_dir/|) {
            # already in deleted_dir
            say "# X\t$_";
        }
        else {
            say "# D\t$_";
            say "mkdir -pv '$deleted_dir/", dirname($_), "'";
            say "mv -v --no-clobber '$_' '$deleted_dir/$_'";
        }
    }
}

my @group;
while (<>) {
    chomp;
    if (m/^[\da-f]{32}$/) {
        process_group(@group) if @group > 1;
        @group = ();
        push @group, $_;
    }
    elsif (m/^\t/) {
        s/^\t//;
        push @group, $_;
    }
    else {
        say "?? $_";
    }
}

process_group(@group) if @group;

