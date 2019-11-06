#! /bin/bash

set -Eeuo pipefail

if [ "${DEBUG:-}" != "" ] ; then
    set -x
fi



function get-data() {

local days="${1:-2}"

local yesterday=$(date -d "1 day ago" '+%Y-%m-%d')
local daybefore=$(date -d "$days day ago" '+%Y-%m-%d')

aws ce get-cost-and-usage  \
    --time-period Start=$daybefore,End=$yesterday \
    --granularity=DAILY \
    --group-by Type=DIMENSION,Key=SERVICE \
    --metrics=UNBLENDED_COST 
}


function transform() {
  jq -r  '[ .ResultsByTime[] | 
          .TimePeriod.Start as $sdate | 
          .Groups[] |  
          [ $sdate, .Keys[], (.Metrics.UnblendedCost.Amount | tonumber) ] 
          ] | sort_by([ .[1], .[0], .[1] ]) | reverse | .[] | @csv' 
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
esac; shift; done

fi

