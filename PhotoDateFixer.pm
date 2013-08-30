package PhotoDateFixer;
use v5.14;
use base 'App::Cmd::Simple';

use List::Util 'first';
use File::Glob ':bsd_glob';
use File::stat;
use File::Touch;
use Image::ExifTool;
use Time::Piece;
use Time::Seconds;

my $TIMEZONE = "-0400";  # EDT
my $tz_offset = 4 * ONE_HOUR;
my $DATE_FORMAT = "%Y-%m-%dT%H:%M:%S %z";

sub opt_spec {
    (
     # [ "dir|d=s", "path to directory of photos" ],
     # [ "photo|p=s", "path to photo file" ],
     [ "show|s", "show information only; do not fix" ],
     [ "fix|f", "fix the dates when needed" ],
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $exif = Image::ExifTool->new();
    $exif->Options(
        DateFormat => $DATE_FORMAT,
        Exclude => [ qw/PreviewImage ThumbnailImage DustRemovalData/ ],
    );

    for my $path (@$args) {
        if (-d $path) {
            process_dir($path, $exif, $opt);
        }
        elsif (-f $path) {
            process_file($path, $exif, $opt);
        }
        else {
            warn "$path: not a file or directory. skipping.\n";
        }
    }
}

sub process_dir {
    my ($path, $exif, $opt) = @_;

    # strip off trailing slashes
    $path =~ s|/+$||;

    my @images = bsd_glob "$path/*.{jpg,JPG}";
    say "found ", scalar @images, " images in <$path>";
    for my $image (@images) {
        process_file($image, $exif, $opt);
    }
}

sub process_file {
    my ($path, $exif, $opt) = @_;

    my $image_info = $exif->ImageInfo($path);
    if ($image_info->{Error}) {
        warn "$path: Error: $image_info->{Error}\n";
        return;
    }

    my $image_date_key = first {$image_info->{$_}} qw/CreateDate DateTimeOriginal ModifyDate SubSecCreateDate SubSecDateTimeOriginal SubSecModifyDate/;

    unless ($image_date_key) {
        warn "$path: No date/time information found in the image. skipping.\n";
        return;
    }

    my $image_date = Time::Piece->strptime($image_info->{$image_date_key}, $DATE_FORMAT);
    # $image_date += $tz_offset unless $image_date->tzoffset;

    my $file_date = localtime(stat($path)->mtime);

    say "$path: FileDate = ", $file_date->strftime($DATE_FORMAT),
        ", ImageDate ($image_date_key) = ", $image_date->strftime($DATE_FORMAT);

    # say "FileDate epoch = ", $file_date->epoch;
    # say "FileDate tzoffset = ", $file_date->tzoffset;
    # say "ImageDate epoch = ", $image_date->epoch;
    # say "ImageDate tzoffset = ", $image_date->tzoffset;

    if ($file_date->epoch + $file_date->tzoffset == $image_date->epoch + $image_date->tzoffset) {
        say "$path: OK";
    }
    else {
        # say "$path: FileDate = $file_date, ImageDate ($image_date_key) = $image_date";
        if ($opt->{fix}) {
            my $timestamp = $image_date->epoch - $file_date->tzoffset;
            if (File::Touch->new(mtime => $timestamp, no_create => 1)->touch($path)) {
                say "$path: mtime fixed. new FileDate = ", localtime(stat($path)->mtime)->strftime($DATE_FORMAT), "\n";
            }
            else {
                warn "$path: could not update mtime.\n";
            }
        }
    }
}

# package main;

# my $fixer = PhotoDateFixer->new({});
# $fixer->run;

1;
