package KD::Aux;

use File::stat;
use Time::localtime;
use Data::Dumper;

my $default_profile = "$ENV{HOME}/.kdprofile";

# yymm_date($date_str)
#
# returns the year and month of $date_str in YYMM format; returns
# undefined if string is malformed, i.e., if string is not formatted
# YYMMDD.
sub yymm_date {
    my $date_str = shift;

    return $1 if ($date_str =~ /^(\d{4})\d{2}$/);
    return undef;
}

# now_timestamp()
#
# returns a timestamp YYYY-MM-DDTHH:MM
sub now_timestamp {
    my $time = localtime();

    return sprintf "%04d-%02d-%02dT%02d:%02d",
        $time->year()+1900, $time->mon()+1, $time->mday(),
        $time->hour(), $time->min();
}

# match($profile, $file)
#
# returns the correct mapping if $file could be matched.
sub match {
    my $profile = shift;
    my $file = shift;

    foreach my $regexp (keys %{$profile->{mapping}}) {
        return $profile->{mapping}->{$regexp} if $file =~ /$regexp/;
    }

    return undef;
}

# new_filename($match, $yymmdd)
#
# returns the new filename for a given match
sub new_filename {
    my $match  = shift;
    my $yymmdd = shift;

    return "$match->{prefix}${yymmdd}$match->{ext}";
}

# get_date_from_mtime($file, $sub)
#
# returns date minus $sub hours in YYMMDD format according to file's
# timestamp. 
sub get_date_from_mtime {
    my $file = shift;
    my $sub = shift;
    $sub = 4 unless $sub;

    my $mtime = localtime((stat($file)->mtime) - (60 * 60 * $sub));
    my $timestamp = sprintf("%02d%02d%02d",
        $mtime->year - 100,
        $mtime->mon + 1,
        $mtime->mday);

    return $timestamp;
}

# get_date_from_filename($filename)
#
# returns date in YYMMDD format if it can find one in $filename.
sub get_date_from_filename {
    my $filename = shift; # mandatory
    my $regex    = shift; # optional

    if ($regex) {
        my (@match) = $filename =~ /$regex/;
        return $match[0] if scalar @match > 0;
    }
    else {
        # try to match 8 digits first, then 6
        my @match;
        @match = $filename =~ /[^\d](\d{2})(\d{2})(\d{2})(\d{2})[^\d]/;
        return sprintf("%02d%02d%02d", $match[1], $match[2], $match[3])
            if scalar @match == 4;
        @match = $filename =~ /[^\d](\d{2})(\d{2})(\d{2})[^\d]/;
        return sprintf("%02d%02d%02d", @match)
            if scalar @match == 3;
    }

    die "Konnte Datum nicht aus Dateinamen extrahieren.\n";
}


# read_profile($profile_file)
#
# reads profile from $profile_file.
sub read_profile {
    my $profile_file = shift;

    unless (-f $profile_file and -r $profile_file) {
        # if there's no profile in $profile_file, search at
        # $default_profile.$profile_file
        if (-r "$default_profile.$profile_file") {
            $profile_file = "$default_profile.$profile_file";
        } else {
            print STDERR "Couldn't find profile file at \"$profile_file\" or "
                ."\"$default_profile.$profile_file\".\n";
            exit 1;
        }

    }

    our $profile;
    if (do $profile_file) {
        return $profile;
    }
    else {
        print STDERR "Unable to parse profile file \"$profile_file\": $!\n";
        exit 2;
    }
}

1;

