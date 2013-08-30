#!/usr/bin/env perl

# usage:
#    find-dupes.pl dir1 [dir2 ... dirN]

use v5.14;

use File::Next;
use File::Slurp qw<slurp>;
use Digest::MD5 qw<md5_hex>;

$|++;

sub image_hash {
    my $file = shift;
    my $contents = slurp $file;
    md5_hex($contents);
}

my $images = File::Next::files(
    {
        file_filter => sub { m/\.(?:jpe?g|png)/i }
    },
    @ARGV);

my $count = 0;
my %image_map;
while (my $image = $images->()) {
    my $hash = image_hash($image);
    say STDERR join "\t", $hash, $image, -s $image;
    push @{$image_map{$hash}}, $image;
    $count++;
}

say STDERR "found $count images.";

for my $hash (keys %image_map) {
    next if scalar @{$image_map{$hash}} < 2;
    say $hash, "\n\t", join "\n\t", sort @{$image_map{$hash}};
}
