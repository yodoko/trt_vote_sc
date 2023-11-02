#!/bin/bash
""" 
To run a function in this snippet :
Modify the values USER_PEM / PROXY_ARGUMENT / CHAIN_ARGUMENT / SC_ADDRESS to the needed values

Then run :
$ source /home/benoit/Bureau/TRT/Smart-contracts/Voting-SC/mx-vote-sc/vote/interaction/add_voters_to_sc.sh
"""

USER_PEM="../wallet/wallet-owner.pem"
OWNER_PEM="../wallet/wallet-mainnet.pem"

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
""" Removed second column from csv file (here it represents the balance) """
sort -u tmp_snapshot.csv -o final_snapshot.csv
""" Removed duplicate values from csv file """

HOLDERS="final_snapshot.csv"
wait
# python3 send_tx_add_voters_to_sc.py --pem "$USER_PEM" --network devnet
python3 send_tx_add_voters_to_sc.py --pem "$OWNER_PEM" --network mainnet
