
remove_newest_dupes
====================


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
