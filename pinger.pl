#!/usr/bin/perl -w

# TODO: Write blog post about this tool
# TODO: Add README.md information
#       - Raison d'etre: basic network stab. tests (used for Triple-O installn validation)
#         Ping tests between multiple hosts
#
#       - Why Perl?  Why external ping?
#         Probably reinventing the wheel but I wanted a quick and dirty (optional)
#         standalone script which would work on multiple OSes, used on:
#             - Windows8 (with cygwin perl+ping)
#             - Ubuntu Linux
#             - HP's hLinux (hardened Linux used for HP Helion nodes)
#       - Usage
# TODO: Add Usage sub
# TODO: Add more comments
# TODO: Meaningful variable names / consistent naming
# TODO: Options to provide history, save history as csv file

use strict;

my $PINGS=2;

my $SUBNET_MATCH='192.168.0';
my @PING_HOSTS=();

#my $SUBNET_MATCH="10.85";
#my @PING_HOSTS=qw/10.85.204.1 10.85.204.3 10.85.204.4 10.85.204.20/;
#my @PING_HOSTS=qw/192.168.0.14 192.168.0.46/;

my $LOOP_COUNT=0;
my $START=localtime();
my $START_S=time();

my $OS="Windows";
if (-d "/boot/") {
    $OS="Linux";
}

my $ADDRESS=undef;
my $PING_OPTS=undef;

if ($OS eq "Windows") {
    $PING_OPTS="-n $PINGS";
    $ADDRESS=(`ipconfig | grep Address | grep $SUBNET_MATCH`)[0];
    chomp($ADDRESS);
    $ADDRESS =~ m/IPv4 Address.*\s+:\s+(\d+\.\d+\.\d+\.\d+)(\/\d+)?/;
    $ADDRESS=$1;

} else {
    $PING_OPTS="-c $PINGS";
    $ADDRESS=(`ip a | grep inet | grep $SUBNET_MATCH`)[0];
    chomp($ADDRESS);
    $ADDRESS =~ m/inet\s+(\d+\.\d+\.\d+\.\d+)(\/\d+)?\s+/;
    $ADDRESS=$1;
}

my $HOSTNAME=`hostname`;
   chomp($HOSTNAME);

my $HOST_INFO="$HOSTNAME\[$ADDRESS $OS]";
my $REPORT_EVERY=10;
my $MAX_COUNT=-1;
my $VERBOSE=0;

my $SLEEP_BETWEEN_PINGS=1;

my %PING_HOST_COUNTS = ();
my %PING_HOST_MSECS  = ();
my %PING_HOST_SUM_TIMEOUT = ();
my %PING_HOST_TMP_TIMEOUT = ();
my %PING_HOST_MAX_TIMEOUT = ();
my %PING_HOST_TIMEOUT = ();
my %PING_HOST_TIMEOUTS = ();

################################################################################
# Subs:
sub initializeVariables {
    %PING_HOST_COUNTS = map { $_ => 0 } @PING_HOSTS;
    %PING_HOST_MSECS  = map { $_ => 0 } @PING_HOSTS;
    %PING_HOST_SUM_TIMEOUT = map { $_ => 0 } @PING_HOSTS;
    %PING_HOST_TMP_TIMEOUT = map { $_ => 0 } @PING_HOSTS;
    %PING_HOST_MAX_TIMEOUT = map { $_ => 0 } @PING_HOSTS;
    %PING_HOST_TIMEOUT = map { $_ => 0 } @PING_HOSTS;
    %PING_HOST_TIMEOUTS = map { $_ => 0 } @PING_HOSTS;
}

sub showStats {
    my $NOW=localtime();
    my $NOW_S=time();
    my $ELAPSED_S = $NOW_S - $START_S;

    # Extract just time:
    $NOW =~ m/(\d+:\d+:\d+)/;
    $NOW = $1;

    $START =~ s/\s+\d{4}\s*$//; # Strip off year:
    $START =~ s/\s\s+//;        # Strip off extra spaces:

    print "\n";
    print "---- Loop$LOOP_COUNT $NOW [PID $$] $HOST_INFO [${ELAPSED_S}s since $START]\n";
    for my $host ( @PING_HOSTS ) {
        my $responsesPC = int(1000 * $PING_HOST_COUNTS{$host} / ($PINGS * $LOOP_COUNT))/10;
        my $delaysMS    = int(1000 * $PING_HOST_MSECS{$host}  / ($PINGS * $LOOP_COUNT))/1000;
        my $time=localtime();
        print "$host responses[$responsesPC%] avg ${delaysMS}ms - ";

	## ## TEST CODE-START:
	## $PING_HOST_TIMEOUTS{$host}++;
	## ## TEST CODE-END:

	if ( $PING_HOST_TIMEOUTS{$host} > 0) {
            my $NUM = $PING_HOST_TIMEOUTS{$host};
            my $AVG = $PING_HOST_SUM_TIMEOUT{$host} / $NUM; # AVG secs
            my $MAX = $PING_HOST_MAX_TIMEOUT{$host}; # MAX secs
            $AVG    = int(10 * $AVG)/10;
            $MAX    = int(10 * $MAX)/10;
            if ($PING_HOST_TIMEOUT{$host} == 0) {
	        print "$NUM   timeouts - avg ${AVG}s, max ${MAX}s\n";
            } else {
                #Still in timeout:
                #$NUM += 1;
                #my $AVG = ($PING_HOST_SUM_TIMEOUT{$host} + $PING_HOST_TMP_TIMEOUT{$host}) / $NUM;
                my $CNUM = $NUM - 1;
	        print "${CNUM}+1 timeouts - avg ${AVG}s, max ${MAX}s\n";
            }
        } else {
	    print"0 timeouts\n";
	}
    }
}

################################################################################
# Read cmd-line args:
while ($_ = shift(@ARGV)) {
    if (/^-v/) { $VERBOSE++; next; }

    if (/^-r/) { $REPORT_EVERY=shift(@ARGV); next; }
    if (/^-m/) { $MAX_COUNT=shift(@ARGV); next; }

    if (/^-s/) { $SUBNET_MATCH=shift(@ARGV); next; }

    # If -h: take rest of arguments as host list
    if (/^-h/) { @PING_HOSTS=@ARGV; @ARGV=(); next; }

    die "Unknown option '$_'";
}

################################################################################
# Main:
if (! @PING_HOSTS ) {
    die "No hosts specified to ping, use -h <list of ips>";
}

initializeVariables();

$SIG{'INT'} = sub {
    showStats();
};

while (1) {
    $LOOP_COUNT++;
    for my $host ( @PING_HOSTS ) {
        my $Successful_Pings_BEFORE=$PING_HOST_COUNTS{$host};

        my $PING_CMD = "ping $PING_OPTS $host";
        my $PING_OP = `$PING_CMD 2>&1`;
        if ($VERBOSE) {
            print "$PING_CMD ==> ", $PING_OP;
        }
        for my $LINE ( split(/\n/, $PING_OP) ) {
            if ($VERBOSE > 1) { print "LINE=<$LINE>\n"; }
            if ($LINE =~ /<1ms /) {
                $PING_HOST_COUNTS{$host}++;
                $PING_HOST_MSECS{$host}+=0.5;
            }
            #Ubuntu: 64 bytes from 10.85.204.1: icmp_seq=1 ttl=64 time=0.044 ms
            if ($LINE =~ /=([\d,\.]+)\s*ms/) {
                $PING_HOST_COUNTS{$host}++;
                $PING_HOST_MSECS{$host}+=$1;
            }
        }

        my $Successful_Pings_AFTER=$PING_HOST_COUNTS{$host};
	if ($Successful_Pings_BEFORE == $Successful_Pings_AFTER) {
	    # All pings timedout

	    # Set start of timeout detection in secs:
            if ($PING_HOST_TIMEOUT{$host} == 0) {
                # Start of a new timeout:
                $PING_HOST_TIMEOUT{$host} = time();
                $PING_HOST_TMP_TIMEOUT{$host} = 0;

	        # increment current timeout length (in loops):
                #$PING_HOST_TIMEOUT{$host}++;

	        # increment timeout count:
                $PING_HOST_TIMEOUTS{$host}++;
            } else {
                # Continuation of timeout:
                my $NOW_S = time();
                $PING_HOST_TMP_TIMEOUT{$host} = $NOW_S - $PING_HOST_TIMEOUT{$host};
            }
	} else {
	    # No, or not all, pings timedout:

            if ( $PING_HOST_TIMEOUT{$host} != 0 ) {
                # End of a timeout:

	        # Calculate sum of timeouts in secs:
                $PING_HOST_SUM_TIMEOUT{$host} += $PING_HOST_TMP_TIMEOUT{$host};
                #$PING_HOST_SUM_TIMEOUT{$host} += ($PINGS * $PING_HOST_TIMEOUT{$host});

	        # Calculate max of timeout in secs:
                if ( $PING_HOST_TMP_TIMEOUT{$host} > $PING_HOST_MAX_TIMEOUT{$host} ) {
	            $PING_HOST_MAX_TIMEOUT{$host}= $PING_HOST_TMP_TIMEOUT{$host};
                }

	        # reset current timeout length:
                $PING_HOST_TIMEOUT{$host}=0;
            }
	}
    }

    if (($MAX_COUNT > 0) && ($LOOP_COUNT == $MAX_COUNT)) {
        showStats();
        exit(0);
    }

    if (($LOOP_COUNT % $REPORT_EVERY) == 0) {
        showStats();
    }
    sleep($SLEEP_BETWEEN_PINGS);
}


