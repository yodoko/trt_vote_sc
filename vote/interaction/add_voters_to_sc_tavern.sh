#!/bin/bash
""" 
To run a function in this snippet :
Modify the values USER_PEM / PROXY_ARGUMENT / CHAIN_ARGUMENT / SC_ADDRESS to the needed values

Then run :
$ source /PATH/TO/FOLDER/vote/interaction/add_voters_to_sc_tavern.sh
"""

USER_PEM="../wallet/wallet-owner.pem"
OWNER_PEM="../wallet/wallet-mainnet.pem"

"""
Let's first make a snapshot of holders with an API call
https://api.multiversx.com/collections/TAVERN-e9b9d6/accounts?size=500
The resulting json is not yet ready for use as is, so now we need to modify the data
"""
getHoldersTavern() {
	curl --location --request GET "https://api.multiversx.com/collections/TAVERN-e9b9d6/accounts?size=588" \
	--header 'Content-Type: application/json'
}
getHoldersTavern > holdersTavern.json

wait

cat holdersTavern.json | jq -r '.[]| join(",")' > snapshotTavern.csv
""" Generated snapshot.csv file """
cut -d, -f1 snapshotTavern.csv > tmp_snapshotTavern.csv
""" Removed second column from csv file (here it represents the balance) """
sort -u tmp_snapshotTavern.csv -o final_snapshotTavern.csv
""" Removed duplicate values from csv file """

HOLDERS="final_snapshotTavern.csv"
wait
# python3 send_tx_add_voters_to_sc_tavern.py --pem "$USER_PEM" --network devnet
python3 send_tx_add_voters_to_sc_tavern.py --pem "$OWNER_PEM" --network mainnet
