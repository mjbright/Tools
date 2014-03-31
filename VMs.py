
import atexit
import sys
import os
import getpass

SYNC=False # Allow aysnc operations

NOTOOLS=[]

DEBUG=1

from pysphere import VIServer

server = VIServer()

MATCH_KEYS=["name", ":name", "status", ":status" ]

OPERS =  [ "list", "on", "off", "shutdown" ]
STATES = [ "suspended", "powered on", "powered off", ]

# "start", "stop", "pause", "resume", "list" ]

################################################################################
# Funcs:

def onExit():
    disconnectESX()
    if len(NOTOOLS) > 0:
        print("\nMachines without VMWare Tools= {")
        for M in NOTOOLS:
            print("  " + M)
        print("}")

def disconnectESX():
    print "Disconnecting ..."
    server.disconnect()

def connectESX(HOST):

    USER = os.environ.get('ESX_USER', None)
    if USER == None:
        print("Env variable 'ESX_USER' is unset")
        USER = raw_input('Enter USER: ')
    
    PASS = os.environ.get('ESX_PASS', None)
    if PASS == None:
        print("Env variable 'ESX_PASS' is unset")
        #PASS = raw_input('Enter PASS: ', dont_print_statement_back_to_screen)
        PASS = getpass.getpass('Enter PASS: ')

    try:
        server.connect(HOST, USER, PASS)
    except:
        print "Failed to connect to " + HOST
        exit(2)

    try:
        atexit.register(onExit)
    except:
        print "Failed to register disconnect to " + HOST
        exit(2)

    print "SERVER type=" + server.get_server_type()
    print "SERVER api=" + server.get_api_version()

def matchName(MATCH, APPLYTO):
    if len(APPLYTO) == 0:
        return MATCH

    for ITEM in APPLYTO:
        if MATCH.lower().find(ITEM.lower()) != -1:
            return ITEM
    return None

def matchFilter(vm, VMNAME, MATCH):
    DEBUG_LEVEL=3

    if len(MATCH) == 0:
        debug(DEBUG_LEVEL, "Pass [No MATCHes defined]")
        return True

    if 'status' in MATCH:
        if not vm.get_status().lower() == MATCH['status'].lower():
            debug(DEBUG_LEVEL, "Block [status]")
            return False

    if ':status' in MATCH:
        if vm.get_status().lower() == MATCH[':status'].lower():
            debug(DEBUG_LEVEL, "Block [!status]")
            return False

    if 'name' in MATCH:
        if not MATCH['name'].lower() in VMNAME.lower():
            debug(DEBUG_LEVEL, "Block [name]")
            return False

    if ':name' in MATCH:
        if MATCH[':name'].lower() in VMNAME.lower():
            debug(DEBUG_LEVEL, "Block [!name]")
            return False

    debug(DEBUG_LEVEL, "Pass []")
    return True

def debug(level, string):
    if DEBUG >= level:
        print("DEBUG: " + string)

def Usage(msg):
    print("Usage:" + msg) # TODO !!

def operate(ESX, FILTER, OPER, ARGS):
    DEBUG_LEVEL=2

    print "ESX=" + ESX + " OPER=" + OPER + " TO=<" + ' '.join(ARGS) + ">"
    connectESX(ESX)
    print "Connected to " + ESX

    if OPER == "list":
        #VMS = server.get_registered_vms(resource_pool='P1', status='poweredOn')
        #VMS = server.get_registered_vms(status='poweredOn')
        VMS = server.get_registered_vms()

        for VM in VMS:
            debug(DEBUG_LEVEL, "VM = <" + VM + ">")
            if matchName(VM, APPLYTO) == None:
                continue

            vm = server.get_vm_by_path(VM)
            debug(DEBUG_LEVEL, "VMA = <" + VM + ">")
            if not matchFilter(vm, VM, FILTER):
                continue;
            debug(DEBUG_LEVEL, "VMF = <" + VM + ">")

            #lb = VM.find('['); rb = VM.find(']')
            #if (lb != 0) or (rb == -1):
            #    raise Exception("Found no Datastore name in " + VM)
            #VMNAME=VM[rb+2:]
            #DSNAME=VM[1:rb]
            #print "VM='" + VMNAME + "'"
            #print "DS='" + DSNAME + "'"
            #vm = server.get_vm_by_name(VMNAME)

            print vm.get_status() + ": " + str(VM)

    if OPER == "on":
        VMS = server.get_registered_vms()
        for VM in VMS:
            if matchName(VM, APPLYTO) == None:
                continue

            vm = server.get_vm_by_path(VM)
            if not matchFilter(vm, VM, FILTER):
                continue;

            vm = server.get_vm_by_path(VM)
            print vm.get_status() + ": " + str(VM)
            vm.power_on(sync_run=SYNC)

    if OPER == "off":
        VMS = server.get_registered_vms()
        for VM in VMS:
            if matchName(VM, APPLYTO) == None:
                continue

            vm = server.get_vm_by_path(VM)
            if not matchFilter(vm, VM, FILTER):
                continue;

            vm = server.get_vm_by_path(VM)
            print vm.get_status() + ": " + str(VM)
            vm.power_off(sync_run=SYNC)

    if OPER == "shutdown":
        VMS = server.get_registered_vms()
        for VM in VMS:
            if matchName(VM, APPLYTO) == None:
                continue

            vm = server.get_vm_by_path(VM)
            if not matchFilter(vm, VM, FILTER):
                continue;

            vm = server.get_vm_by_path(VM)
            print vm.get_status() + ": " + str(VM)
            try:
                vm.shutdown_guest()
            except Exception as  e:
                print str(e)
                toolsMsg="VMware Tools is not running".lower()
                if str(e).lower().find(toolsMsg) == -1:
                    raise e # It's another Exception
                print("VMWare Tools is not running on " + VM)

            NOTOOLS.append(VM)
                

    if OPER == "suspend":
        VMS = server.get_registered_vms()
        for VM in VMS:
            if matchName(VM, APPLYTO) == None:
                continue

            vm = server.get_vm_by_path(VM)
            if not matchFilter(vm, VM, FILTER):
                continue;

            vm = server.get_vm_by_path(VM)
            print vm.get_status() + ": " + str(VM)
            vm.standby_guest(sync_run=SYNC)


################################################################################
# Args:

ESX=None

OPER=None
APPLYTO=[]

FILTER={}

ARG=0

ARGS_DEBUG_LEVEL=3

while ARG < (len(sys.argv)-1):
    ARG = ARG + 1
    debug(ARGS_DEBUG_LEVEL, "ARG[" + str(ARG) + "]=" + sys.argv[ARG])

    if sys.argv[ARG] == "ASYNC":
        SYNC=False
        continue

    if sys.argv[ARG] == "SYNC":
        SYNC=True
        continue

    if sys.argv[ARG] == "esx":
        ESX = sys.argv[ARG+1]
        debug(ARGS_DEBUG_LEVEL, "ESX=" + ESX)
        ARG = ARG + 1
        continue

    if sys.argv[ARG] == "match":
        ARG = ARG + 1
        key = sys.argv[ARG]

        if key == "status":
            if not sys.argv[ARG+1].lower() in STATES:
                raise Exception("Invalid status: <" + sys.argv[ARG+1] + ">")

        #if (key in MATCH_KEYS) or (":" +  key) in MATCH_KEYS:
        if key in MATCH_KEYS:
            ARG = ARG + 1
            FILTER[key] = sys.argv[ARG]
            continue

        raise Exception("Invalid filter cond: <" + sys.argv[ARG] + ">")
     

    if ESX == None: 
        raise Exception("No ESX specified")

    if OPER == None:
        if not sys.argv[ARG] in OPERS:
            raise Exception("Not a known operation <" + sys.argv[ARG] + ">")
        OPER = sys.argv[ARG]
        continue

    APPLYTO=sys.argv[ARG:len(sys.argv)]
    break


if ESX == None:
    Usage("Missing ESX argument")
    sys.exit(1)

if OPER == None:
    Usage("Missing OPER argument")
    sys.exit(1)

operate(ESX, FILTER, OPER, APPLYTO)


exit(0)

################################################################################
# Main:


exit(0)


vm = server.get_vm_by_path("[datastore] path/to/file.vmx")
#vm.power_on()


