Tools
=====


This scripts are a fairly random collection of tools which hopefully may be useful to someone.

The intention is that they be in any scripting language whether it be Perl, Python, Bash, Ruby etc etc,
and whilst they generally assume a Unix/Linux platform they should all run under Cygwin on Windows also.

If I start adding Windows (non-Cygwin) specific scripts, in PowerShell for example, then I'll probably create
a separate project for that.

Enjoy.


List of Tools
=============

remove_newest_dupes:
--------------------


Usage: ./remove_newest_dupes.pl
  ./remove_newest_dupes.pl [-h|-help] [-do] [-old] [-v] [<FILES>]

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
    ./remove_newest_dupes.pl

  To remove oldest duplicated files in current dir:
    ./remove_newest_dupes.pl -old

  To remove oldest duplicated files from provided list:
    ./remove_newest_dupes.pl -old FILE1 FILE1_NEWER FILE1_VERYOLD FILE2 FILE2_OLD
  Would remove files FILE1 FILE1_VERYOLD FILE2_OLD";
  Keeping oldest copies of FILE1, FILE2: FILE1_NEWER FILE2
