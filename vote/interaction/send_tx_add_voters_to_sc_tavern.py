import binascii
from tokenize import Hexnumber

from pathlib import Path
from multiversx_sdk_network_providers import ProxyNetworkProvider
from multiversx_sdk_core import Address, Transaction, AccountNonceHolder, TokenPayment
from multiversx_sdk_wallet import UserPEM
from multiversx_sdk_wallet import UserSigner
from multiversx_sdk_core.transaction_builders import ContractCallBuilder
from multiversx_sdk_core.transaction_builders import DefaultTransactionBuildersConfiguration

import argparse

import pandas as pd
pd.options.mode.chained_assignment = None  # default='warn'

# ---------------------------------------------------------------- #
#                         INPUTS
# ---------------------------------------------------------------- #
parser = argparse.ArgumentParser()
parser.add_argument("--pem", help="The wallet that sends txs (needs to hold the EGLDs)", required=True)
parser.add_argument("--network", help="The network (options : 'mainnet' or 'devnet')", required=True)
args = parser.parse_args()

if(args.network == 'devnet'):
	provider = ProxyNetworkProvider("https://devnet-gateway.multiversx.com")
	id_chain="D"
	config = DefaultTransactionBuildersConfiguration(chain_id="D")
	sc_address=Address.from_bech32("erd1qqqqqqqqqqqqqpgq5kdhkkjtvgjcgl2yelkj7nxtu8emwm04musqu3qsf7")
if(args.network == 'mainnet'):
	provider = ProxyNetworkProvider("https://gateway.multiversx.com")
	id_chain="1"
	config = DefaultTransactionBuildersConfiguration(chain_id="1")
	sc_address=Address.from_bech32("erd1qqqqqqqqqqqqqpgqqt9ffqdege3nwkhyhmpypna7lpurjpzt92qqgc2gay")

# Read the input file
data_df = pd.read_csv("final_snapshotTavern.csv", header=None) # Header is set to None, because csv input file has no header, values start on row 1

liste=[]
for address in data_df[0]:
	liste.append(Address.from_bech32(address))

# ---------------------------------------------------------------- #
#                        ADDRESS PARAMS
# ---------------------------------------------------------------- #
signer = UserSigner.from_pem_file(Path(args.pem))
pem = UserPEM.from_file(Path(args.pem))
address = pem.secret_key.generate_public_key().to_address("erd")

print("Public key", pem.public_key.hex())
print("Address", address)

account_on_network = provider.get_account(address)

nonce_holder = AccountNonceHolder(account_on_network.nonce)
# ---------------------------------------------------------------- #
#                   MAIN ADD VOTERS FONCTION
# ---------------------------------------------------------------- #
def addVoters(tx_signer, receiver, addresses_list):
	builder = ContractCallBuilder(
        config,
        contract=receiver,
        function_name="addVoters",
        caller=address,
        call_arguments=addresses_list,
        gas_limit=600000000
    )
	tx = builder.build()
	tx.nonce = nonce_holder.get_nonce_then_increment()
	tx.signature = tx_signer.sign(tx)
	hash_tx = provider.send_transaction(tx)
	print("Added holders vote right")
	print("HASH : ", hash_tx)
print("LONGUEUR : ", len(liste))
addVoters(signer, sc_address, liste)
