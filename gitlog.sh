
LASTID=""

MAXLOOPS=1000

#git log --oneline | while [ $MAXLOOPS -gt 0 ]; do
git log --oneline | while true; do

    let MAXLOOPS=MAXLOOPS-1
    [ $MAXLOOPS -le 0 ] && break

    ########################################
    # Get IDLINE, extract git ID:
    read IDLINE;
    ID=$(echo $IDLINE | awk '{print $1;}')

    ########################################
    # Detect end of file:
    [ -z "$ID" ] && { exit 0; }

    ########################################
    # Show difference with previous commit:
    echo
    echo "============================================================================="
    echo "==" $(git log --oneline $ID | grep $ID);
    [ ! -z "$LASTID" ] && { git diff -r $ID -r $LASTID | cat; };

    ########################################
    # Save away LASTID:
    LASTID=$ID;
done

