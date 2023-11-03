""" 
To run a function in this snippet :
$ source /PATH/TO/FOLDER/vote/interaction/a_new_snippets.sh && functionToCall
"""
VOTER_CONTRACT="../output/vote.wasm"

USER_PEM="../wallet/wallet-owner.pem"

PROXY_ARGUMENT="--proxy=https://devnet-gateway.multiversx.com"
CHAIN_ARGUMENT="--chain=D"

SC_ADDRESS="erd1qqqqqqqqqqqqqpgqludp4hayf7nl04tp2898q6wp24p07z2kmusqg2hyzl"


build_voter() {
    (set -x; mxpy --verbose contract build)
}

deploy_voter() {
    local OUTFILE="out-voter.json"

    (set -x; mxpy --verbose contract deploy --bytecode=$VOTER_CONTRACT \
        --pem=$USER_PEM \
        $PROXY_ARGUMENT $CHAIN_ARGUMENT \
        --outfile="$OUTFILE" --recall-nonce --gas-limit=600000000 \
        --send \
        || return)

    local RESULT_ADDRESS=$(mxpy data parse --file="$OUTFILE" --expression="data['emitted_tx']['address']")
    local RESULT_TRANSACTION=$(mxpy data parse --file="$OUTFILE" --expression="data['emitted_tx']['hash']")

    echo ""
    echo "Deployed contract with:"
    echo "  \$RESULT_ADDRESS == ${RESULT_ADDRESS}"
    echo "  \$RESULT_TRANSACTION == ${RESULT_TRANSACTION}"
    echo ""
}

upgrade_voter() {
    (set -x; mxpy --verbose contract upgrade "$SC_ADDRESS" \
    --pem=$USER_PEM --bytecode=$VOTER_CONTRACT \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --gas-limit=60000000 \
    --outfile="upgrade-devnet.interaction.json" --recall-nonce \
    --send \
    || return
    )
}

startRound() {
    QUESTION="Shall we improve this dapp ?"

    (set -x; mxpy --verbose contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="startRound" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments str:"$QUESTION" \
    --send \
    || return
    )
}

addOptions() {
    local OPTION1="No..."
    local OPTION2="Yes !"

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addOptions" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments str:"$OPTION1" str:"$OPTION2" \
    --send \
    || return
    )
}

endRound() {
    ROUND_ID=$1

    (set -x; mxpy --verbose contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="endRound" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments $ROUND_ID \
    --send \
    || return
    )
}


addMultipleHolders() {
    local A1=$1
    local A2=$2
    local A3=$3
    local A4=$4
    local A5=$5

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments ${A1} ${A2} ${A3} ${A4} ${A5} \
    --send \
    || return
    )
}

addHolder() {
    local ADDRESS=$1

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments ${ADDRESS} \
    --send \
    || return
    )
}

getCurrentRoundQuestion() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="getCurrentRoundQuestion"
    )
}

getRounds() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getRounds"
    )
}

getCurrentRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getCurrentRound"
    )
}

getVotesForCurrentRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getVotesForCurrentRound"
    )
}

getVotesForIdRound() {
    local ROUND=$1

    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getVotesForIdRound" \
    --arguments ${ROUND}
    )
}

hasVotedForIdRound() {
    local ROUND=$1
    local ADDRESS=$2

    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="hasVotedForIdRound" \
    --arguments ${ROUND} ${ADDRESS}
    )
}

getNbHoldersForIdRound() {
    local ROUND=$1

    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbHoldersForIdRound" \
    --arguments ${ROUND}
    )
}

getNbHoldersForCurrentRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbHoldersForCurrentRound" 
    )
}

getNbVotersForIdRound() {
    local ROUND=$1

    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbVotersForIdRound" \
    --arguments ${ROUND}
    )
}
getNbVotersForCurrentRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbVotersForCurrentRound"
    )
}

getCurrentRoundOptions() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getCurrentRoundOptions" 
    )
}

vote() {
    local ID=$1
    local OPTION=$2

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT \
    --function="vote" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments ${ID} ${OPTION} \
    --send \
    || return

    )
}

getNbVotesForIdRoundAndIdOption() {
    local ROUND=$1
    local OPTION=$2
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbVotesForIdRoundAndIdOption" \
    --arguments ${ROUND} ${OPTION} 
    )
}

getNbVotesForCurrentRoundAndIdOption() {
    local OPTION=$1
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbVotesForCurrentRoundAndIdOption" \
    --arguments ${OPTION} 
    )
}

checkVotersAddresses() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getVotersAddresses"
    )
}
checkVotes() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getVotes"
    )
}
getNbVotesForProposalIdAndOption() {
    local ID=$1
    local OPTION=$2
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="nbVotesForProposalIdOption" \
    --arguments ${ID} ${OPTION}
    )
}


removeHolders() {
    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT \
    --function="removeHolders" \
    --recall-nonce \
    --gas-limit=60000000 \
    --send \
    || return
    )
}
removeVotes() {
    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT \
    --function="removeVotes" \
    --recall-nonce \
    --gas-limit=60000000 \
    --send \
    || return
    )
}

removeAll() {
    (set -x; mxpy --verbose contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT \
    --function="removeAll" \
    --recall-nonce \
    --gas-limit=60000000 \
    --send \
    || return
    )
}
