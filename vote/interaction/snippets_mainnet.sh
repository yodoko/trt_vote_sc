""" 
To run a function in this snippet :
$ source /home/benoit/Bureau/TRT/Smart-contracts/Voting-SC/mx-vote-sc/vote/interaction/a_new_snippets.sh && functionToCall
"""
VOTER_CONTRACT="../output/vote.wasm"

OWNER_PEM="../wallet/wallet-mainnet.pem"

PROXY_ARGUMENT="--proxy=https://gateway.multiversx.com"
CHAIN_ARGUMENT="--chain=1"

SC_ADDRESS="erd1qqqqqqqqqqqqqpgqcxv93atx35gag37m6rh8x89lax7gf37m92qqezwne2"

build_voter() {
    (set -x; mxpy --verbose contract build)
}

deploy_voter() {
    local OUTFILE="out-voter.json"

    (set -x; mxpy --verbose contract deploy --bytecode=$VOTER_CONTRACT \
        --pem=$OWNER_PEM \
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
    --pem=$OWNER_PEM --bytecode=$VOTER_CONTRACT \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --gas-limit=60000000 \
    --outfile="upgrade-devnet.interaction.json" --recall-nonce \
    --send \
    || return
    )
}

startRound() {
    QUESTION="What should be the threshold for rewards distribution per knight ?"

    (set -x; mxpy --verbose contract call "$SC_ADDRESS" \
    --pem=$OWNER_PEM \
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
    local OPTION1="0.05 EGLD"
    local OPTION2="0.1 EGLD"
    local OPTION3="0.2 EGLD"

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$OWNER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addOptions" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments str:"$OPTION1" str:"$OPTION2" str:"$OPTION3" \
    --send \
    || return
    )
}

endRound() {
    ROUND_ID=$1

    (set -x; mxpy --verbose contract call "$SC_ADDRESS" \
    --pem=$OWNER_PEM \
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
    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$OWNER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments ${ADDRESS1} ${ADDRESS2} ${ADDRESS3} ${ADDRESS4} ${ADDRESS5} ${ADDRESS6} ${ADDRESS7} ${ADDRESS8}\
    --send \
    || return
    )
}

addHolder() {

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$OWNER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments $1 \
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
    local ADDRESS_VOTER=erd1gmawg88dsmef3ltchdljpt863gwm0w8tq36nz74qdsglqj5rx8zqs4wlpa

    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="hasVotedForIdRound" \
    --arguments ${ROUND} ${ADDRESS_VOTER}
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


vote() {
    local ID=$1
    local OPTION=$2

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$OWNER_PEM \
    $PROXY_ARGUMENT \
    --function="vote" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments ${ID} ${OPTION} \
    --send \
    || return

    )
}
# getCurrentExchangeRate

getCurrentExchangeRate() {
    (set -x; mxpy contract query erd1qqqqqqqqqqqqqpgq35qkf34a8svu4r2zmfzuztmeltqclapv78ss5jleq3 \
    $PROXY_ARGUMENT \
    --function="getCurrentExchangeRate"
    )
}
