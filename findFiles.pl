#!/usr/bin/perl -w

use strict;

use File::Find;

my $REVERSE=0;
my $MAX_ELEMS=-1;

# STAT elements:
use constant SIZE  => 1;
use constant MTIME => 2;
use constant ATIME => 3;
use constant CTIME => 4;

# FILE/DIR choice:
use constant FILE => 100;
use constant DIR  => 101;

my $FILE_MODE=FILE;

my $MODE=SIZE;

my %FILE_INFO=();

################################################################################
# subs:

sub usage {
    print STDERR "Usage:\n";
    print STDERR "  $0 [-r] [-<NUM>] [-size|-mtime|-ctime|-atime] <DIR>\n";
    print STDERR "\n";
    print STDERR "   -size:   order by file/dir size\n";
    print STDERR "   -mtime:  order by file/dir mtime\n";
    print STDERR "   -ctime:  order by file/dir ctime\n";
    print STDERR "   -atime:  order by file/dir atime\n";
    print STDERR "\n";
    print STDERR "   -f: only list files\n";
    print STDERR "   -d: only list directories\n";
    print STDERR "   -r: reverse 'descending' order of listing\n";
    print STDERR "   -<NUM>: show only N elements\n";
    print STDERR "\n";
}

sub collectFileInfo {

    #print "FULL='".$File::Find::name."'\n";

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
       $atime,$mtime,$ctime,$blksize,$blocks)
           = stat($_);

    if (($FILE_MODE == FILE) && (-d $_)) { return; }
    if (($FILE_MODE == DIR)  && (-f $_)) { return; }

    INFO: {
        if ($MODE == SIZE) { $FILE_INFO{$File::Find::name} = $size; return; }
        if ($MODE == MTIME) { $FILE_INFO{$File::Find::name} = $mtime; return; }
        if ($MODE == ATIME) { $FILE_INFO{$File::Find::name} = $atime; return; }
        if ($MODE == CTIME) { $FILE_INFO{$File::Find::name} = $ctime; return; }
    }
}

sub formatInfo {
    my $FILE=shift;

    #print "$FILE => $FILE_INFO{$FILE}\n";
    INFO: {
        if ($MODE == SIZE)  { return sprintf "%10d", $FILE_INFO{$FILE}; }
        if ($MODE == MTIME) { return scalar(localtime($FILE_INFO{$FILE})); }
        if ($MODE == ATIME) { return scalar(localtime($FILE_INFO{$FILE})); }
        if ($MODE == CTIME) { return scalar(localtime($FILE_INFO{$FILE})); }
    }
}

################################################################################
# cli args:

my $DIR=undef;

while ($_ = shift(@ARGV)) {

    if (/-r/) { $REVERSE=1; next; }
    if (/-(\d+)/) { $MAX_ELEMS=$1; next; }

    if (/-f/)  { $FILE_MODE=FILE; next; }
    if (/-d/)  { $FILE_MODE=DIR;  next; }

    if (/-size/)  { $MODE=SIZE; next; }
    if (/-mtime/) { $MODE=MTIME; next; }
    if (/-atime/) { $MODE=ATIME; next; }
    if (/-ctime/) { $MODE=CTIME; next; }

    $DIR=$_;
}

if (!defined($DIR)) {
    usage();
    die "No directory specified";
}
if (! -d $DIR) {
    usage();
    die "Not a directory '$DIR'";
}

################################################################################
# main:

find(\&collectFileInfo, $DIR);

my @sorted;
if ($REVERSE) {
    @sorted = sort {$FILE_INFO{$b} <=> $FILE_INFO{$a}} keys %FILE_INFO;
} else {
    @sorted = sort {$FILE_INFO{$a} <=> $FILE_INFO{$b}} keys %FILE_INFO;
}

if ($MAX_ELEMS > 0) {
    @sorted=$sorted[0 ... $MAX_ELEMS];
}

foreach (@sorted) {
    print formatInfo($_)." ".$_."\n";
}


