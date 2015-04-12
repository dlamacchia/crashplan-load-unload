#!/bin/zsh -f
#
# From:	Timothy J. Luoma
# Mail:	luomat at gmail dot com
# Date:	2013-02-26
#
#	NOTE: In order for this script to work, the following lines must be added to /etc/sudoers (without the leading '#' of course)
#
#	%admin ALL=NOPASSWD: /bin/launchctl list
#	%admin ALL=NOPASSWD: /bin/launchctl load /Library/LaunchDaemons/com.crashplan.engine.plist
# 	%admin ALL=NOPASSWD: /bin/launchctl unload /Library/LaunchDaemons/com.crashplan.engine.plist
#
# [dml]: update 04/12/15 with formatting and support for osx notifications via applescript

NAME="$0:t"
PLIST="/Library/LaunchDaemons/com.crashplan.engine.plist"

# if the file doesn't exist, stop right there
[[ -e "$PLIST" ]] || exit 0

msg () {
    STICKY=""
    DIE='no'
    for ARGS in "$@"
    do
	case "$ARGS" in
	    -s|--sticky)
		STICKY=--sticky
		shift
		;;

	    -d|--die)
		DIE=yes
		STICKY=--sticky
		shift
		;;
	esac
    done
    MSG="$@"
    osascript \
        -e "on run(argv)" \
        -e "return display notification item 1 of argv" \
        -e "end" \
        -- "$NAME: $MSG"
    echo "$NAME: $MSG"
    [[ "$DIE" = "yes" ]] && exit 1
}

if [ "`ps cx | egrep ' CrashPlan menu bar$'`" != "" ]
then
    # the CrashPlan menu bar is running
    msg "Telling CrashPlan menu bar app to quit"
    osascript -e 'tell application "CrashPlan menu bar" to quit'
fi


# Get a list of all of root's loaded plists
ROOT_LOADED=$(sudo launchctl list)

if [[ "$ROOT_LOADED" == "" ]]
then
    # if we didn't get anything in response, die ugly
    msg --die "ROOT_LOADED is empty"
    exit 1
fi

# if we got this far, we did get some response from ROOT_LOADED

echo "$ROOT_LOADED" | fgrep -q com.crashplan.engine
EXIT="$?"

if [[ "$EXIT" = "0" ]]
then
    EXIT=1
    sudo /bin/launchctl unload "$PLIST" && EXIT=0
    if [ "$EXIT" = "0" ]
    then
	msg "UN-loaded CrashPlan plist successfully"
    else
	msg --die "Failed to unload CrashPlan"
    fi

    exit $EXIT
else
    # if we get here, crashplan is not loaded, so we'll exit, because we have the state we wanted
    msg "CrashPlan already unloaded"
    exit 0
fi

# If we get here, something unexpected happened
exit 2

#EOF
