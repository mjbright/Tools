#!/usr/bin/perl -w

use strict;

# Specify external "cksum" tool to use to identify duplicate/unique files:
my $CKSUM="md5sum";

use constant RM_NEWEST => 1;
use constant RM_OLDEST => 2;

my $RM=RM_NEWEST;

my $VERBOSE=0;
my $DO_REMOVALS=0;

my %XXXEST_FILE_BY_CKSUM=();
my %SEEN=();

my @ITEM_LIST=();

my $FILES=0;
my $UNIQUE_FILES=0;
my $DELETED_FILES=0;
my $KEPT_FILES=0;

################################################################################
# SUBS:

sub usage {

## START USAGE: ########################################
    print <<EOUSAGE;

Usage: $0
  $0 [-h|-help] [-do] [-old] [-v] [<FILES>]

    -h|help: Show this message

    -do:  Doit - actually delete the selected files
    -old: Removed oldest dupes
    -v:   Increase verbosity

This script detects duplicate files and removes the newest duplicates
  (or oldest if the -old option is specified)

This can be useful for example if a cron script creates some daily status files
e.g. the output of dpkg -l
So we keep only the files as they change and not any intermediate duplicates.

e.g.
  To remove newest duplicated files in current dir:
    $0

  To remove oldest duplicated files in current dir:
    $0 -old

  To remove oldest duplicated files from provided list:
    $0 -old FILE1 FILE1_NEWER FILE1_VERYOLD FILE2 FILE2_OLD
  Would remove files FILE1 FILE1_VERYOLD FILE2_OLD";
  Keeping oldest copies of FILE1, FILE2: FILE1_NEWER FILE2

EOUSAGE
## END USAGE: ##########################################

}

sub get_mtime {
    my $file = shift;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks)
           = stat($file);

    return $mtime;
}

################################################################################
# CMD-LINE ARGS:

while ($_ = shift(@ARGV)) {
    if (/^-(h|help)$/) {
        usage();
        exit(0);
    }

    if (/^-(v+)$/) {
        $VERBOSE += length($1);
        next;
    }

    if (/^-do/) {
        $DO_REMOVALS=1;
        next;
    }

    if (/^-old$/) {
        $RM=RM_OLDEST;
        next;
    }

    if (-f $_) {
        push(@ITEM_LIST, $_);
        next;
    }

    usage();
    die "Unknown option: '$_'";
}

if (! @ITEM_LIST) {
    opendir(DIR, ".");
        @ITEM_LIST=grep(!/^\.+$/, grep(-f, readdir(DIR)));
    closedir(DIR)
}

################################################################################
# MAIN:

for $_ ( @ITEM_LIST ) {
    $FILES++;
    if ($SEEN{$_}) {
        if ($VERBOSE > 1) {
            print "ALREADY SEEN: $_\n";
        }
        next;
    }
    $SEEN{$_}=1;
    $UNIQUE_FILES++;

    my $cksum = `$CKSUM < $_`;
    chomp($cksum);

    if ( ! defined( $XXXEST_FILE_BY_CKSUM{$cksum} ) ) {
        $XXXEST_FILE_BY_CKSUM{$cksum} = $_;
        if ($VERBOSE > 1) {
            print "NEW<$cksum>: $_ [" , get_mtime($_) , "]\n";
        }
        next;
    }

    if ($VERBOSE > 1) {
        print "OLD<$cksum>: $_ [" , get_mtime($_) , "]\n";
    }

    my $prev_file = $XXXEST_FILE_BY_CKSUM{$cksum};
    my $prev_mtime=get_mtime( $prev_file );
    my $mtime=get_mtime( $_ );

    if ($mtime == $prev_mtime) {
        warn "NOT HANDLED: ($mtime == $prev_mtime)";
        next;
    }

    my $NEWER = $mtime > $prev_mtime;
    my $OLDER = $mtime < $prev_mtime;
    #my $REMOVE_OLDEST = ($RM == RM_OLDEST) && $NEWER;
    #my $REMOVE_NEWEST = ($RM == RM_NEWEST) && $OLDER;

    if (($RM == RM_OLDEST) && $OLDER) {
        print "$_ is OLDER than $prev_file => rm $_\n";
        $XXXEST_FILE_BY_CKSUM{$cksum} = $prev_file;
        if ($DO_REMOVALS) {
            print "unlink($_);\n";
            $DELETED_FILES++;
            unlink($_);
        }
        next;
    }

    if (($RM == RM_OLDEST) && $NEWER) {
        print "$_ is NEWER than $prev_file => rm $prev_file\n";
        $XXXEST_FILE_BY_CKSUM{$cksum} = $_;
        if ($DO_REMOVALS) {
            print "unlink($prev_file);\n";
            $DELETED_FILES++;
            unlink($prev_file);
        }
        next;
    }

    if (($RM == RM_NEWEST) && $NEWER) {
        print "$_ is NEWER than $prev_file => rm $_\n";
        $XXXEST_FILE_BY_CKSUM{$cksum} = $prev_file;
        if ($DO_REMOVALS) {
            print "unlink($_);\n";
            $DELETED_FILES++;
            unlink($_);
        }
        next;
    }

    if (($RM == RM_NEWEST) && $OLDER) {
        print "$_ is OLDER than $prev_file => rm $prev_file\n";
        $XXXEST_FILE_BY_CKSUM{$cksum} = $_;
        if ($DO_REMOVALS) {
            print "unlink($prev_file);\n";
            $DELETED_FILES++;
            unlink($prev_file);
        }
        next;
    }
}

END {
    if ($VERBOSE) {
        $KEPT_FILES=keys %XXXEST_FILE_BY_CKSUM;

        print "Removed $DELETED_FILES of $FILES files\n";
        if ( $UNIQUE_FILES != $FILES) {
            print "Saw $UNIQUE_FILES unique files of $FILES\n";
        }
    }

    if ($VERBOSE > 1) {
        print "Kept $KEPT_FILES of $FILES files:\n";

        for my $cksum ( keys %XXXEST_FILE_BY_CKSUM ) {
            print "  $XXXEST_FILE_BY_CKSUM{$cksum}\n";
        }
    }
}



