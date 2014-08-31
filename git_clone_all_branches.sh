
PAUSE=1
PAUSE=0

################################################################################
# Functions:

press() {
    echo $*
    [ $PAUSE -eq 0 ] && return

    echo "Press <return> to continue"
    read _DUMMY

    [ "$_DUMMY" = "q" ] && exit 0
    [ "$_DUMMY" = "Q" ] && exit 0
}

die() {
    echo "$0: die - $*" >&2
    exit 1
}

echoCmd() {
    echo
    echo "-- [$PWD]"
    echo "-- $*"
    $*
}

################################################################################
# Args:

REGEX=""

while [ ! -z "$1" ];do
    case $1 in
        -r) shift; REGEX=$1;;
        -p) PAUSE=1;;
        -np) PAUSE=0;;
        *) die "Unknown option '$1'";;
    esac
    shift
done

################################################################################
# Main:

echo
echo "Getting master URL: "
URL=$(git remote -v | grep fetch | awk '{print $2;}')
echo $URL
GIT_URL=${URL}.git

echo
echo "Getting chapter branches: "

MAIN=__MAIN__

#[ ! -d BRANCHES ] && mkdir BRANCHES
[ ! -d BRANCHES/$MAIN ] && {
    mkdir -p BRANCHES/$MAIN;

    echo;
    echo "Cloning master from $GIT_URL";
    echoCmd time git clone --mirror $GIT_URL BRANCHES/$MAIN/.git;
}

cd BRANCHES/$MAIN
    if [ -z "$REGEX" ];then
        BRANCHES=$(git branch -a)
    else
        BRANCHES=$(git branch -a | grep -E $REGEX)
    fi
cd -

cd BRANCHES/
#BRANCHES=$(ls -1 | grep -v $MAIN)

for branch in $BRANCHES
do
    #[ $chapter -lt 10 ] && chapter="0${chapter}"

    #BRANCH=chapter_${chapter}
    DIR=$branch

    echo
    press "==== [$PWD] Copying master to $DIR"

    cp -a $MAIN $DIR

    cd $DIR
        #git branch $branch
        #git checkout $branch
        #git pull remote $branch
        git branch -a | grep $branch
        echoCmd git config --bool core.bare false;
        echoCmd git checkout $branch
    cd -
done


