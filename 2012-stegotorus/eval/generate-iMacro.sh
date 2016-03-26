#!/bin/bash
# generate iMacro

################################################################################
# variables with default values

declare -i IM_TIMEOUT=60

################################################################################
# helper functions:

usage () {
if [ $# -gt 0 ]; then
    echo " *** ERROR: $1"
fi
cat << EOF

usage: $0 [<OPTIONS>] <OUT_DIR> <EXP_PREFIX> <FF_IMACROS_DIR> <TYPE> [<NUMBER>]*

Generate iMacros script for web browsing on-the-fly.

OUT_DIR         is the root of where to write any result files from the macro.
EXP_PREFIX      is the prefix for any result files to be used.
FF_IMACROS_DIR  is the Firefox iMacros directory where to save macro.  
TYPE            defines the starting web site and <NUMBERS> the pages and links followed.

TYPE      | NUMBERS
----------------------------
tor       | empty
fb-browse | list of link positions to follow, such as 5 2 3
fb-post   | n = number of random status updates 
google    | {1..3}
hrw       | {1..100} x {1..10}
amnesty   | {1..9} x {1..10}
alexa     | {1..10}

OPTIONS:
   -h      Show this message
   -t      Timeout for iMacro script (default: ${IM_TIMEOUT}s)
EOF
}

################################################################################
# parse command line:

OUT_DIR=
FF_IMACROS_DIR=
while getopts “ht:” OPTION
do
    case $OPTION in
        h|\?)
            usage; exit 1
            ;;
	t)
	    IM_TIMEOUT=$OPTARG
	    ;;
    esac
    shift $((OPTIND-1)); OPTIND=1 
done

# now $@ has remaining arguments:
if [ $# -lt 4 ]; then
    usage "need at least 4 arguments"; exit 1
fi

# test mandatory arguments:
OUT_DIR=$1

EXP_PREFIX=$2

FF_IMACROS_DIR=$3

TYPE=$4

DIR=`dirname $0`

################################################################################
# generate common header of macro

cat > $FF_IMACROS_DIR/temp.iim << EOF
VERSION BUILD=7401004
SET !VAR1 $OUT_DIR
SET !VAR2 $EXP_PREFIX
SET !TIMEOUT $IM_TIMEOUT
TAB T=1
TAB CLOSEALLOTHERS
EOF

################################################################################
# evaluate type

# common header for facebook
case $TYPE in
    fb-browse|fb-post)
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
URL GOTO=https://www.facebook.com/
' --- try to log out first if already logged in (and ignore error)
SET !ERRORIGNORE YES
SET !TIMEOUT 10
TAG POS=1 TYPE=DIV ATTR=CLASS:menuPulldown
TAG POS=1 TYPE=INPUT:SUBMIT FORM=ID:logout_form ATTR=VALUE:Log<SP>Out
SET !ERRORIGNORE NO
SET !TIMEOUT $IM_TIMEOUT
' --- log in
TAG POS=1 TYPE=INPUT:TEXT FORM=ACTION:https://www.facebook.com/login.php?login_attempt=1 ATTR=ID:email CONTENT=alice.defiance@gmail.com
SET !ENCRYPTION NO
TAG POS=1 TYPE=INPUT:PASSWORD FORM=ACTION:https://www.facebook.com/login.php?login_attempt=1 ATTR=ID:pass CONTENT=defiance2012
TAG POS=1 TYPE=INPUT:SUBMIT FORM=ID:login_form ATTR=VALUE:Log<SP>In
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE={{!VAR2}}-fb-logged-in.png
' --- select "News Feed"
SET !TIMEOUT_STEP 12
SET !EXTRACT_TEST_POPUP NO
' to allow pages to display before proceeding
TAG POS=2 TYPE=DIV ATTR=TXT:News<SP>Feed
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE={{!VAR2}}-fb-news-feed.png
EOF
	;;
    *) ;;  # ignore rest
esac

case $TYPE in
    tor)
	;;
    fb)
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
URL GOTO=http://facebook.com/
EOF
	;;
    alexa)
	# test that $5 in {1..10}
	if [[ $# -lt 3 || $5 -lt 1 || $5 -gt 10 ]]; then
	    usage "need rank {1..10} for top alexa sites"; exit 1
	fi
	# read $5-th line from alexa.txt
	SITE=`head -n $5 $DIR/alexa.txt | tail -n 1 | cut -d' ' -f2`
	if [ -z "$SITE" ]; then
	    usage "Couldn't find $5-th site in $DIR/alexa.txt"; exit 5
	fi
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
URL GOTO=http://$SITE/
EOF
	;;
    fb-browse)
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
SET !ERRORIGNORE YES
EOF
	args=("$@")
	for i in "${args[@]:4}"; do
	    cat >> $FF_IMACROS_DIR/temp.iim << EOF
' --- click on $i-th story
' find anchor in div with class "uiAttachmentTitle"
TAB T=1
SET !EXTRACT NULL
TAG POS=$i TYPE=DIV ATTR=CLASS:uiAttachmentTitle&&TXT:* EXTRACT=TXT
TAG POS=1 TYPE=A ATTR=TXT:{{!EXTRACT}}
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE={{!VAR2}}-fb-news$i.png
WAIT SECONDS=2
EOF
	done
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
SET !ERRORIGNORE NO
EOF
	;;
    fb-post)
	    cat >> $FF_IMACROS_DIR/temp.iim << EOF
' --- post status update
SET !DATASOURCE {{!VAR1}}/{{!VAR2}}.csv
SET !DATASOURCE_COLUMNS 1
EOF
	    for ((i=1;i<=$5;i++)); do
		cat >> $FF_IMACROS_DIR/temp.iim << EOF
'   - $i-th status update
SET !DATASOURCE_LINE $i
TAG POS=1 TYPE=TEXTAREA FORM=ACTION:/ajax/updatestatus.php ATTR=NAME:xhpc_message
TAG POS=1 TYPE=TEXTAREA FORM=ACTION:/ajax/updatestatus.php ATTR=NAME:xhpc_message_text CONTENT={{!COL1}}
WAIT SECONDS=1
TAG POS=1 TYPE=LABEL ATTR=CLASS:submitBtn<SP>uiButton<SP>uiButtonConfirm&&TXT:
WAIT SECONDS=3
TAG POS=2 TYPE=DIV ATTR=TXT:News<SP>Feed
EOF
	    done
	    ;;
    google)
	# test that $5 in {1..3}
	if [[ $# -lt 2 || $5 -lt 1 || $5 -gt 3 ]]; then
	    usage "number for link {1..3} missing or not in allowable range"; exit 1
	fi
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
SET !ERRORIGNORE YES
SET !TIMEOUT 15
URL GOTO=http://news.google.com/
WAIT SECONDS=3
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE=screenshot1.png
SET !ERRORIGNORE NO
SET !TIMEOUT $IM_TIMEOUT
SET !EXTRACT_TEST_POPUP NO
' --- search for n-th title in "Top Stories" section
' 1) <span class="title">
TAG POS=1 TYPE=SPAN ATTR=CLASS:title&&TXT:* EXTRACT=TXT
WAIT SECONDS=2
' 2) n-th <h2 class="title sel"> or <h2 class="title">
SET !EXTRACT NULL
TAG POS=R$5 TYPE=H2 ATTR=CLASS:title*&&TXT:* EXTRACT=TXT
WAIT SECONDS=2
' 3) find anchor with extracted text: works only if blocking popo-ups turned off
SET !ERRORIGNORE YES
SET !TIMEOUT 120
TAG POS=1 TYPE=A ATTR=TARGET:_blank&&TXT:{{!EXTRACT}}
EOF
	;;
    hrw)
	# test that $5 in {1..100} and $6 in {1..10}
	if [[ $# -lt 3 || $5 -lt 1 || $5 -gt 100 || $6 -lt 1 || $6 -gt 10 ]]; then
	    usage "numbers for page {1..100} or link {1..3} missing or not in allowable range"; exit 1
	fi
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
URL GOTO=http://www.hrw.org/en/news/list
WAIT SECONDS=1
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE=screenshot1.png
SET !EXTRACT_TEST_POPUP NO
' --- enter page number in form field
' 1) <h6 class='page-title'>News</h6>
TAG POS=1 TYPE=H6 ATTR=CLASS:page-title&&TXT:News
' 2) <form action="/en/news/list" method="post" ...
'    <input type="text" name="page" ...
TAG POS=R1 TYPE=INPUT:TEXT FORM=ACTION:/en/news/list ATTR=ID:edit-page&&NAME:page CONTENT=$5
TAG POS=R1 TYPE=INPUT:SUBMIT FORM=ID:tic-pager-form ATTR=ID:edit-submit
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE=screenshot2.png
' --- search for n-th title in "News" section
' 3) <h6 class='page-title'>News</h6>
TAG POS=1 TYPE=H6 ATTR=CLASS:page-title&&TXT:News
WAIT SECONDS=3
' 4) n-th <div class='view-field field-node-title'>
SET !EXTRACT NULL
TAG POS=R$6 TYPE=DIV ATTR=CLASS:view-field<SP>field-node-title&&TXT:* EXTRACT=TXT
' 5) follow embedded anchor
TAG POS=1 TYPE=A ATTR=TXT:{{!EXTRACT}}
EOF
	;;
    amnesty)
	# test that $5 in {1..9} and $6 in {1..10}
	if [[ $# -lt 3 || $5 -lt 1 || $5 -gt 9 || $6 -lt 1 || $6 -gt 10 ]]; then
	    usage "numbers for page {1..9} or link {1..3} missing or not in allowable range"; exit 1
	fi
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
URL GOTO=http://www.amnesty.org/en/features-news-and-updates
WAIT SECONDS=2
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE=screenshot1.png
SET !EXTRACT_TEST_POPUP NO
EOF
	if [ $5 -gt 1 ]; then
	    cat >> $FF_IMACROS_DIR/temp.iim << EOF
' --- follow link with page number if not 1
TAG POS=1 TYPE=A ATTR=TITLE:Go<SP>to<SP>page<SP>$5
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE=screenshot2.png
EOF
	fi
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
' --- find n-th h3
SET !EXTRACT NULL
TAG POS=$6 TYPE=H3 ATTR=CLASS:title*&&TXT:* EXTRACT=TXT
WAIT SECONDS=2
' --- follow first link with extracted text
TAG POS=1 TYPE=A ATTR=TXT:{{!EXTRACT}}
EOF
	;;
    *)
	usage "type $TYPE not recognized"; exit 1
	;;
esac

# common footer for facebook
case $TYPE in
    fb-browse|fb-post)
	cat >> $FF_IMACROS_DIR/temp.iim << EOF
' --- log out (at least, try)
TAB T=1
SET !ERRORIGNORE YES
SET !TIMEOUT 10
TAG POS=1 TYPE=DIV ATTR=CLASS:menuPulldown
TAG POS=1 TYPE=INPUT:SUBMIT FORM=ID:logout_form ATTR=VALUE:Log<SP>Out
EOF
	;;
    *) ;;  # ignore rest
esac

################################################################################
# generate common footer of macro:
# need to create last screenshot to signal other script that we are done

cat >> $FF_IMACROS_DIR/temp.iim << EOF
SAVEAS TYPE=PNG FOLDER={{!VAR1}} FILE=last_screenshot.png
EOF
