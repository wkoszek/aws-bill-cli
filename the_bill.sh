#! /bin/bash

set -Eeuo pipefail


if [ "${DEBUG:-}" != "" ] ; then
    set -x
fi

export ACCOUNT_ID=$(aws sts get-caller-identity | jq -r .Account)

function get-data() {

local days="${1:-1}"

DATECMD=date
if [ `uname -s` = 'Darwin' ]; then
    DATECMD=gdate
    if [ "`which $DATECMD`" = "" ]; then
        echo "You don't have GNU 'date' command."
        echo "You should brew install coreutils"
        exit 64
    fi
fi

local yesterday=$($DATECMD -d "0 day ago" '+%Y-%m-%d')
local daybefore=$($DATECMD -d "$days day ago" '+%Y-%m-%d')
local script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

aws ce get-cost-and-usage  \
    --time-period Start=$daybefore,End=$yesterday \
    --granularity=DAILY \
    --group-by Type=DIMENSION,Key=SERVICE \
    --metrics=UNBLENDED_COST \
    --filter file://$script_dir/credit_filters.json
}


function transform() {
  jq -r  '[ .ResultsByTime[] | 
          .TimePeriod.Start as $sdate |
          "'$ACCOUNT_ID'" as $account | 
          .Groups[] |  
          [ $account, $sdate, .Keys[], (.Metrics.UnblendedCost.Amount | tonumber) ] 
          ] | sort_by([ .[2], .[1], .[2] ]) | reverse | .[] | @csv' 
}


function show_help() {
cat << __DOC__

$1 [--days=n] csv|json
 
	Write per-service costs for the last n days to STDOUT in CSV or JSON format. 

cat JSONFILE | $1 json_to_csv

    Convert JSON On STDIN to CSV on STDOUT

__DOC__
}


days=2

if [[ "$#" -eq 0  ]]; then
	show_help $0
else 
while [[ "$#" -gt 0 ]]; do case $1 in
     -d|--days) 
        days="$2"; 
        shift
     ;;
     --days=*) 
		days="${1#*=}";
	 ;;
	 -h|--help)
		show_help $0
		exit
	 ;;
     get-data|json)
	 	get-data $days
	 ;;
	 json_to_csv)
	    transform
     ;;
	 csv)
		get-data $days | transform
     ;;
     me)
        aws sts get-caller-identity
     ;;
esac; shift; done

fi

