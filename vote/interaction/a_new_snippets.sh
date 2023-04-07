""" 
To run a function in this snippet :
$ source /home/benoit/Bureau/TRT/Smart-contracts/Voting-SC/mx-vote-sc/vote/interaction/a_new_snippets.sh && functionToCall
"""
PEM_FILE="./ping-pong.pem"
VOTER_CONTRACT="output/vote.wasm"
ADDER_CONTRACT="output/adder.wasm"

USER_PEM="../wallet/wallet-owner.pem"
TEST_PEM="wallet/wallet-test.pem"
TEST_PEM_2="wallet/wallet-test-2.pem"
PROXY_ARGUMENT="--proxy=https://devnet-gateway.multiversx.com"
CHAIN_ARGUMENT="--chain=D"

ADDRESSBIDON="erd1x85f4zksuvezkycz94n52umdtvdhvlzhc6jn76k2n0fmymxqqydql7kh"
ADDRESS1="erd1dlxwydw4j6qxpyckkqf6j2rmzj86qv32ndnun23pxj00z5ctmusq8z7xjm"
ADDRESS2="erd1gmawg88dsmef3ltchdljpt863gwm0w8tq36nz74qdsglqj5rx8zqs4wlpa"
ADDRESS3="erd1zq7ksw2xdmx2a2u5hp7sx99q9rtwc0264yzhwewu7qn0mkj3v8esq6ujam"
ADDRESS4="erd1j780ukjyynka96ye35ldzfqc7egqfhasdtndr0wy7v5r2t2h4sxqzkhw0a"
ADDRESS5="erd1zs5d2zerz2d884vl5mtdf995rnwq3qeswy4s95x8nynkw4ctqz2qczw7zh"
ADDRESS6="erd1rkw3qc0esse3c8d22zgn56hkfgsyjda3wlmp3qmqx5h5hftwqvzqfean87"
ADDRESS7="erd1gn92uccz28ch6lpqnyg407zcfzra62px5da4sdf5tksp8urg92qqar7tk6"
ADDRESS8="erd1a6506smh2h0ql5pcvjl4svjmlukgmdu35evuhladu0z4ujr92k4sx9lgra"
ADDRESS9="erd1ggke2c38pgmuzreqx6ly0ew04544gpa0ggl8cw44drjc9sseyajqw4ncw9"
ADDRESSMAX="erd1jmugpsnlnq7jwgzejzklq43r0865pyv6ead2fqxs8mtdjrkasqkq997asn"
ADDRESSBIDON="erd1x85f4zksuvezkycz94n52umdtvdhvlzhc6jn76k2n0fmymxqqydql7kh6n"

SC_ADDRESS_1="erd1qqqqqqqqqqqqqpgqszyjcyp9xt6en6904zldzvntzfmyzq8emusqacj9vj"
SC_ADDRESS_2="erd1qqqqqqqqqqqqqpgqjp9u39u4c5uutdpu49qd9dy4sw95674jmusqhc552y"
SC_ADDRESS_3="erd1qqqqqqqqqqqqqpgq9qa97qfpzxu5kyk24nraw8r7dw07yz5xmusqzhws0e"
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
    --gas-limit=600000000 \
    --outfile="upgrade-devnet.interaction.json" --recall-nonce \
    --send \
    || return
    )
}

startRound() {
    QUESTION="Do you like this new dapp ?"

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

addMultipleHolders() {
    local a3=erd1qqqqqqqqqqqqqpgq9rjd7z4h2c6806k8nmhcskayw2j7t05pv8es0qh93y

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments ${a3} ${ADDRESS1} ${ADDRESS2} ${ADDRESS3} ${ADDRESS4} ${ADDRESS5} ${ADDRESS6} ${ADDRESS7} ${ADDRESS8}\
    --send \
    || return
    )
}

addHolder() {

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$USER_PEM \
    $PROXY_ARGUMENT $CHAIN_ARGUMENT \
    --function="addVoters" \
    --recall-nonce \
    --gas-limit=20000000 \
    --arguments ${ADDRESS9} ${ADDRESSBIDON}\
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
    local ROUND=3

    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getVotesForIdRound" \
    --arguments ${ROUND}
    )
}

getNbHoldersForIdRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbHoldersForIdRound" \
    --arguments 1
    )
}

getNbHoldersForCurrentRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbHoldersForCurrentRound" 
    )
}

getNbVotersForIdRound() {
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbVotersForIdRound" \
    --arguments 1
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



voteTest() {
    local ID=0
    local OPTION=3

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$TEST_PEM \
    $PROXY_ARGUMENT \
    --function="vote" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments ${ID} ${OPTION} \
    --send \
    || return

    )
}
voteTest2() {
    local ID=2
    local OPTION=3

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$TEST_PEM_2 \
    $PROXY_ARGUMENT \
    --function="vote" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments ${ID} ${OPTION} \
    --send \
    || return

    )
}
voteTestWorking() {
    local ID=1
    local OPTION=3

    (set -x; mxpy contract call "$SC_ADDRESS" \
    --pem=$TEST_PEM \
    $PROXY_ARGUMENT \
    --function="vote" \
    --recall-nonce \
    --gas-limit=6000000 \
    --arguments ${ID} ${OPTION} \
    --send \
    || return

    )
}

vote() {
    local ID=1
    local OPTION=2

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
    local ROUND=1
    local OPTION=2
    (set -x; mxpy contract query "$SC_ADDRESS" \
    $PROXY_ARGUMENT \
    --function="getNbVotesForIdRoundAndIdOption" \
    --arguments ${ROUND} ${OPTION} 
    )
}

getNbVotesForCurrentRoundAndIdOption() {
    local OPTION=3
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
    local ID=1
    local OPTION=0
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
wwwineSC() {
    (set -x; mxpy contract query erd1qqqqqqqqqqqqqpgqtylxl3ll2emxtgt929n08zut8plvqyyll3jsjdva4t \
    --proxy=https://gateway.multiversx.com \
    --function="getStakedNonces" \
    --arguments erd13w5hlehc42zvhd9u78ylrac9axntn9p9jqn9kvy3c052l8rmt2yqa59l76
    )
}
