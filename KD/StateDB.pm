package KD::StateDB;

use strict;
use diagnostics;

use DBI;
use File::Basename;
use Date::Calc qw(Add_Delta_Days Today);

# table scheme
# (symbols declared with 'our' are referenced by outside this module)
my  $tsname    = 'kd';
our $tsfile    = 'oldfilename';
our $tsnewname = 'newfilename';
our $tstime    = 'timestamp';
my  $tsfarmid  = 'farmid';
my  $tscheme = "CREATE TABLE $tsname (
        $tsfile    VARCHAR(4096) NOT NULL,
        $tsfarmid  INTEGER NOT NULL,    
        $tsnewname VARCHAR(4096),
        $tstime    DATE
);";

# constructor
#
# 
sub new {
    my $class = shift;
    my $self = shift;

    die "Need farm id in StateDB constructor.\n" unless $self->{farmid};

    # print "Connecting to database... " if $self->{verbose};
    $self->{dbh} = DBI->connect(@{$self->{dbi_connect}});
    die $DBI::errstr if not $self->{dbh};
    # print "done.\n" if $self->{verbose};

    my $tableexists = scalar $self->{dbh}->tables('%', '%', $tsname, '');
    if (not $tableexists) {
        print "Creating table $tsname... " if $self->{verbose};
        my $rows = $self->{dbh}->do($tscheme);
        if ($rows eq '0E0') {
            print "done.\n" if $self->{verbose};
        }
        else {
            die $DBI::errstr;
        }
    }

    # turn on unicode (and read
    # http://search.cpan.org/~adamk/DBD-SQLite-1.33/lib/DBD/SQLite.pm#Database_Handle_Attributes )
    $self->{dbh}->{sqlite_unicode} = 1;
    
    # don't fsync() after each commit (means a HUGE performance increase)
    $self->{dbh}->do('PRAGMA synchronous = OFF');

    bless $self, $class;

    return $self;
}

# destructor
#
# close connection to avoid complaint by older clients
sub DESTROY {
    my $self = shift;

    $self->{dbh}->disconnect();
}

# mark_done($file, $newname)
#
# marks $file as done in the database; returns 1 on succes, 0 otherwise
sub mark_done {
    my $self = shift;
    my $file = shift;
    my $newname = shift;

    my $time = `date +"%Y-%m-%d %H:%M"`;
    chomp $time;
    my $ar = $self->{dbh}->do("INSERT INTO $tsname
            ($tsfile, $tsnewname, $tstime, $tsfarmid) VALUES (?,?,?,?)",
        undef,
        basename($file), $newname, $time, $self->{farmid});

    if ($ar eq '0E0') {
        print $DBI::errstr;
        return 0;
    }
    return $ar;
}

# unmark($file, $type)
#
# unmarks $file as done. The new file name is searched for by default.
# This can be changed by setting $type to 'old'.
sub unmark {
    my $self = shift;
    my $file = shift;
    my $type = shift;

    my $old_or_new = $tsnewname;
    $old_or_new = $tsfile if defined $type and $type eq 'old';
    my $ar = $self->{dbh}->do(
        "DELETE FROM $tsname WHERE $old_or_new=? AND $tsfarmid=?",
        undef, basename($file), $self->{farmid});

    if ($ar eq '0E0') {
        print "$file not found, nothing to unmark.\n";
        return 0;
    }
    else {
        my $entries = ($ar == 1) ? $file : "$ar entries matching $file";
        print "Unmarked $entries.\n";
        return $ar;
    }
}

# already_processed_file($file, $newname)
#
# returns 1 if the file has already been processed and 0 otherwise.
sub already_processed_file {
    my $self    = shift;
    my $file    = shift;
    my $newname = shift;

    my $oldfile = $self->{dbh}->selectrow_hashref(
        "SELECT * FROM $tsname WHERE $tsfarmid=? AND ($tsfile=? OR "
            ."$tsnewname=?)", undef,
        $self->{farmid}, basename($file), $newname);

    if ($oldfile) {
        print "\"".basename($file)."\" has already been processed at "
            ."$oldfile->{$tstime}. " if $self->{verbose};
        print "Its new name is \"$oldfile->{$tsnewname}\"."
            if ($oldfile->{$tsnewname} ne basename($file)) and $self->{verbose};
        print "\n" if $self->{verbose};
        return 1;
    }
    else {
        return 0;
    }
}

# purge_old($days)
#
# purges all entries older than $days days from table $tsname
sub purge_old {
    my $self = shift;
    my $days = shift;
    $days = 50 unless $days;

    my $date = sprintf "%04d-%02d-%02d", Add_Delta_Days(Today(), -$days);
    my $ar = $self->{dbh}->do("DELETE FROM $tsname WHERE $tstime < ? "
        ."AND $tsfarmid=?",
        undef, $date, $self->{farmid});
    print "Purged $ar old (prior $date) entries from status file.\n"
        if $ar ne '0E0';
}

# get_all($sql)
#
# fetches all entries from the table $tsname and returns them as a
# two-dimensional array. It takes an optional SQL string in which one
# can refine the query.
sub get_all {
    my $self = shift;
    my $sql = shift;
    
    # replace WHERE with AND at the beginning
    $sql =~ s/^\s*WHERE\s+(.*)/AND $1/i;

    my $completed = $self->{dbh}->selectall_arrayref(
        "SELECT * FROM $tsname WHERE $tsfarmid=? $sql", undef,
        $self->{farmid});

    return $completed;
}

# get($newname, $time)
#
# fetches all entries matching $newname and $time from the table $tsname
# and returns them as a two-dimensional array.
sub get {
    my $self = shift;
    my $newname = shift;
    my $time = shift;

    my $matches = $self->{sbh}->selectall_arrayref(
        "SELECT * FROM $tsname WHERE $tsfarmid=? AND $tsnewname=? AND $tstime=?",
        undef, $self->{farmid}, $newname, $time);

    return $matches;
}

1;

