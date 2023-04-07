#!/bin/bash
""" 
To run a function in this snippet :
Modify the values USER_PEM / PROXY_ARGUMENT / CHAIN_ARGUMENT / SC_ADDRESS to the needed values

Then run :
$ source /home/benoit/Bureau/TRT/Smart-contracts/Voting-SC/mx-vote-sc/vote/interaction/add_voters_to_sc.sh
"""

USER_PEM="../wallet/wallet-owner.pem"
PROXY_ARGUMENT="--proxy=https://devnet-gateway.multiversx.com"
CHAIN_ARGUMENT="--chain=D"

SC_ADDRESS="erd1qqqqqqqqqqqqqpgqludp4hayf7nl04tp2898q6wp24p07z2kmusqg2hyzl"
"""
Let's first make a snapshot of holders with an API call
https://api.multiversx.com/collections/TRT-956a03/accounts?size=500
The resulting json is not yet ready for use as is, so now we need to modify the data
"""
getHolders() {
	curl --location --request GET "https://api.multiversx.com/collections/TRT-956a03/accounts?size=500" \
	--header 'Content-Type: application/json'
}
getHolders > holders.json

wait

cat holders.json | jq -r '.[]| join(",")' > snapshot.csv
""" Generated snapshot.csv file """
cut -d, -f1 snapshot.csv > tmp_snapshot.csv
""" Removed second column from csv file (here is represents the balance) """
sort -u tmp_snapshot.csv -o final_snapshot.csv
""" Removed duplicate values from csv file """

HOLDERS="final_snapshot.csv"

IFS=$'\n' read -d '' -r -a lines < $HOLDERS
len=${#lines[@]}
echo "Holders count : ${len}"

addVoters() {
    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments $1 $2 $3 $4 $5 $6 $7 $8 $9 \
    --send \
    || return
    )
}

for (( i=0; i<=$len/9; i++));
do
    echo "======================================"
    echo "adding ${lines[$((9 * $i))]}"
    echo "======================================"
    addVoters ${lines[$((9 * $i))]} ${lines[$((9 * $i + 1))]} ${lines[$((9*$i+2))]} ${lines[$((9*$i+3))]} ${lines[$((9*$i+4))]} ${lines[$((9*$i+5))]} ${lines[$((9*$i+6))]} ${lines[$((9*$i+7))]} ${lines[$((9*$i+8))]}
    echo "====================================== Waiting 6 seconds for next transaction"
    sleep 10
done
 
