#![no_std]

multiversx_sc::imports!();
multiversx_sc::derive_imports!();

static ERR_NOT_HOLDER: &[u8] = 
b"Address is not a holder for this vote round";
static ERR_ALREADY_VOTED: &[u8] = 
b"Address already voted for this round";
static ERR_VOTE_ROUND_INCORRECT: &[u8] = 
b"Vote round submitted is not valid or already finished";
static ERR_OPTION_NOT_VALID: &[u8] = 
b"Vote option submitted is not valid";

#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode)]
pub struct Holder<M: ManagedTypeApi> {
    pub id_proposal: u32,
    pub address: ManagedAddress<M>,
    pub has_voted: bool
}

#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, TypeAbi)]
pub struct Round<M: ManagedTypeApi> {
    pub id_proposal: u32,
    pub question: ManagedBuffer<M>,
    pub finished: bool
}

#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, ManagedVecItem, TypeAbi)]
pub struct VoteOption<M: ManagedTypeApi> {
    pub id_proposal: u32,
    pub id_option:u32,
    pub value: ManagedBuffer<M>
}

#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, TypeAbi)]
pub struct Vote {
    pub id_proposal: u32,
    pub id_option: u32
}

// return id option , option en clair, nombre de votes pour cette option
#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, ManagedVecItem, TypeAbi)]
pub struct VoteResult<M: ManagedTypeApi> {
    pub id_option: u32,
    pub option_value: ManagedBuffer<M>,
    pub count: u32
}


#[multiversx_sc::contract]
pub trait Voter {

    #[init]
    fn init(&self) {
        self.current_round().set_if_empty(0u32);
    }

    // owner endpoints

    #[only_owner]
    #[endpoint(startRound)]
    fn start_round(&self, question: ManagedBuffer<Self::Api>) {
        self.current_round().update(|x| *x += 1);
        self.rounds().push(
            &Round {
                id_proposal: self.current_round().get(),
                question: question,
                finished: false
            });
    }

    #[only_owner]
    #[endpoint(endRound)]
    fn end_round(&self, index: u32) {
        for round in self.rounds().iter() {
            if round.id_proposal == index {
                self.rounds().set(
                    index.try_into().unwrap(),
                    &Round {
                        id_proposal: round.id_proposal,
                        question: round.question,
                        finished: true
                    });
            }
        }
    }

    #[only_owner]
    #[endpoint(addOptions)]
    fn add_options(&self, options: MultiValueEncoded<ManagedBuffer<Self::Api>>) {
        let current_round = self.current_round().get();
        for option in options {

            self.valid_options().insert(
                Vote {
                    id_proposal: current_round,
                    id_option: self.round_options(current_round).len() as u32 + 1
                }
            );
            self.round_options(current_round).insert(
                VoteOption {
                    id_proposal: current_round,
                    id_option: self.round_options(current_round).len() as u32 + 1,
                    value: option
                }
            );
        }
    }

        
    #[only_owner]
    #[endpoint(addVoters)]
    fn add_voters(
        &self, 
        addresses: MultiValueEncoded<ManagedAddress>,
    ) {
        for unique in addresses {
            if self.blockchain().is_smart_contract(&unique) {
                continue;
            }
            self.voters().insert(
                Holder {
                    id_proposal: self.current_round().get(),
                    address: unique,
                    has_voted: false
                }
            );
        }
    }

    // user / holder endpoints
    #[endpoint]
    fn vote(&self, pid: u32, optid: u32) {
        self.require_active_round(pid);
        self.require_unvoted(pid);
        self.require_valid_holder(pid);
        self.require_valid_option_for_proposal(pid, optid);

        self.voters().swap_remove(&Holder {
            id_proposal: pid,
            address: self.blockchain().get_caller(),
            has_voted: false
        });

        self.voters().insert(Holder {
            id_proposal: pid,
            address: self.blockchain().get_caller(),
            has_voted: true
        });

        self.round_votes(pid).push(&Vote {
            id_proposal: pid,
            id_option: optid
        });
    }


    // functions
    
    fn require_current_round(&self, pid: u32) {
        require!
        (
            self.current_round().get() == pid,
            ERR_VOTE_ROUND_INCORRECT
        );
    }
    
    fn require_active_round(&self, pid: u32) {
        for round in self.rounds().iter() {
            if round.id_proposal == pid {
                require!
                (
                    round.finished == false,
                    ERR_VOTE_ROUND_INCORRECT
                );
            }
        }
    }
    
    fn require_valid_holder(&self, id_round: u32) {
        require!
        (
            self.voters().contains(&Holder {
                id_proposal: id_round,
                address: self.blockchain().get_caller(),
                has_voted: false
            }),
            ERR_NOT_HOLDER
        );
    }
    
    fn require_unvoted(&self, id_round: u32) {
        require!
        (
            !self.voters().contains(&Holder {
                id_proposal: id_round,
                address: self.blockchain().get_caller(),
                has_voted: true
            }),
            ERR_ALREADY_VOTED
        );
    }

    fn require_valid_option_for_proposal(&self, propid: u32, optid: u32) {
        require!
        (
            self.valid_options().contains(&Vote {
                id_proposal: propid,
                id_option: optid
            }),
            ERR_OPTION_NOT_VALID
        );
    }


    // views

    #[view(getCurrentRound)]
    #[storage_mapper("current_round")]
    fn current_round(&self) -> SingleValueMapper<u32>;

    #[view(getCurrentRoundOptions)]
    fn current_round_options(&self) -> MultiValueEncoded<VoteOption<Self::Api>> {
        let mut options = MultiValueEncoded::<Self::Api, VoteOption<Self::Api>>::new();
        for option in self.round_options(self.current_round().get()).iter() {
            if option.id_proposal == self.current_round().get() {
                options.push(option);
            }
        }
        return options;
    }

    #[view(getCurrentRoundQuestion)]
    fn current_round_question(&self) -> ManagedBuffer<Self::Api> {
        let mut current_round_question = ManagedBuffer::new();
        for question in self.rounds().iter() {
            if question.id_proposal == self.current_round().get() {
                current_round_question = question.question;
            }
        }
        return current_round_question;
    }

    #[view(getNbHoldersForIdRound)]
    fn get_nb_holders_for_id_round(&self, id_round: u32) -> i32 {
        let mut nb_holders = 0;
        for voter in self.voters().iter() {
            if voter.id_proposal == id_round && voter.has_voted == false {
                nb_holders += 1;
            }
        }
        return nb_holders;
    }

    #[view(getNbHoldersForCurrentRound)]
    fn get_nb_holders_for_current_round(&self) -> i32 {
        let mut nb_holders = 0;
        for voter in self.voters().iter() {
            if voter.id_proposal == self.current_round().get() {
                nb_holders += 1;
            }
        }
        return nb_holders;
    }

    #[view(getNbVotersForIdRound)]
    fn get_nb_voters_for_id_round(&self, id_round: u32) -> i32 {
        let mut nb_voters = 0;
        for voter in self.voters().iter() {
            if voter.id_proposal == id_round && voter.has_voted == true {
                nb_voters += 1;
            }
        }
        return nb_voters;
    }

    #[view(getNbVotersForCurrentRound)]
    fn get_nb_voters_for_current_round(&self) -> i32 {
        let mut nb_voters = 0;
        for voter in self.voters().iter() {
            if voter.id_proposal == self.current_round().get() && voter.has_voted == true {
                nb_voters += 1;
            }
        }
        return nb_voters;
    }

    #[view(getNbVotesForIdRoundAndIdOption)]
    fn get_nb_votes_for_id_round_and_id_option(
        &self, id_round: u32, id_option: u32
    ) -> i32 {
        let mut count = 0;
        for vote in self.round_votes(id_round).iter() {
            if vote.id_proposal == id_round && vote.id_option == id_option {
                count += 1;
            }
        }
        return count;
    }

    #[view(getNbVotesForCurrentRoundAndIdOption)]
    fn get_nb_votes_for_current_round_and_id_option(
        &self, id_option: u32
    ) -> i32 {
        let mut count = 0;
        let current_round =  self.current_round().get();
        for vote in self.round_votes(current_round).iter() {
            if vote.id_proposal == current_round && vote.id_option == id_option {
                count += 1;
            }
        }
        return count;
    }

    #[view(getVotesForCurrentRound)]
    fn get_votes_for_current_round(&self) -> 
    MultiValueEncoded<VoteResult<Self::Api>> {
        let mut result=
            ManagedVec::<Self::Api, VoteResult<Self::Api>>::new();
        let mut result_final = 
            MultiValueEncoded::<Self::Api, VoteResult<Self::Api>>::new();
        let mut counters:[[u32; 2];10] = [[0;2];10];
        
        let mut index = 0;

        for option in self.round_options(self.current_round().get()).iter() {
            if option.id_proposal == self.current_round().get() {
                counters[index][0] = option.id_option;
                counters[index][1] = 0;
                result.push(
                    VoteResult {
                        id_option: option.id_option,
                        option_value: option.value.clone(),
                        count: counters[index][1]
                    }
                );
            }
            index += 1;
        }
        index = 0;
        for option in result.iter() {
            for vote in self.round_votes(self.current_round().get()).iter() {
                if option.id_option == vote.id_option {
                    counters[index][1] = counters[index][1] + 1;
                }
            }
            result_final.push(VoteResult{
                id_option: counters[index][0],
                option_value: option.option_value.clone(),
                count: counters[index][1]
            });
            index += 1;
            
        }
        return result_final;
    }


    #[view(getVotesForIdRound)]
    fn get_votes_for_id_round(&self, id_round: u32) -> 
    MultiValueEncoded<VoteResult<Self::Api>> {
        let mut result=
            ManagedVec::<Self::Api, VoteResult<Self::Api>>::new();
        let mut result_final = 
            MultiValueEncoded::<Self::Api, VoteResult<Self::Api>>::new();
        let mut counters:[[u32; 2];10] = [[0;2];10];
        
        let mut index = 0;

        for option in self.round_options(id_round).iter() {
            counters[index][0] = option.id_option;
            counters[index][1] = 0;
            result.push(
                VoteResult {
                    id_option: option.id_option,
                    option_value: option.value.clone(),
                    count: counters[index][1]
                }
            );
            index += 1;
        }
        index = 0;
        for option in result.iter() {
            for vote in self.round_votes(id_round).iter() {
                if option.id_option == vote.id_option {
                    counters[index][1] = counters[index][1] + 1;
                }
            }
            result_final.push(VoteResult{
                id_option: counters[index][0],
                option_value: option.option_value.clone(),
                count: counters[index][1]
            });
            index += 1;
            
        }
        return result_final;
    }

    // storage

    #[storage_mapper("voters")]
    fn voters(&self) -> UnorderedSetMapper<Holder<Self::Api>>;

    #[view(getRounds)]
    #[storage_mapper("rounds")]
    fn rounds(&self) -> VecMapper<Round<Self::Api>>;

    #[storage_mapper("round_votes")]
    fn round_votes(&self, round: u32) -> VecMapper<Vote>;

    #[view(getValidOptions)]
    #[storage_mapper("valid_options")]
    fn valid_options(&self) -> UnorderedSetMapper<Vote>;

    #[storage_mapper("round_options")]
    fn round_options(&self, round: u32) -> UnorderedSetMapper<VoteOption<Self::Api>>; //VecMapper ?

}
