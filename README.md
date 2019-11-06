
# the_bill.sh

Gets per-day, per-service costs from AWS using AWS CLI. 

Prerequisites:

  - Authentication is present (using `AWS_*` - style environment vars, for example)
    (see https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html )
  - IAM users have been granted billing access. 
    (see https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html )
  - `jq`  if you want CSV output
    (see https://stedolan.github.io/jq/ )

Formats: JSON or CSV (using jq).

``` 


./the_bill.sh [--days=n] csv|json
 
	Write per-service costs for the last n days to STDOUT in CSV or JSON format. 

cat JSONFILE | ./the_bill.sh json_to_csv

    Convert JSON On STDIN to CSV on STDOUT

``` 
