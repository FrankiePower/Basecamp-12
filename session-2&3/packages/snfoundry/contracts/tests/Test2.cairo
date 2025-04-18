use contracts::Counter::{ICounterDispatcher, ICounterDispatcherTrait};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::{ContractAddress};

const ZERO_COUNT: u32 = 0;

fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

// util deploy function
fn _deploy_(init_value: u32) -> (ICounterDispatcher, IOwnableDispatcher) {
    //declare contract
    let contract_class = declare("Counter").unwrap().contract_class();

    // serialize constructor
    let mut calldata: Array<felt252> = array![];
    init_value.serialize(ref calldata);
    OWNER().serialize(ref calldata);

    // deploy contract
    let (contract_address, _) = contract_class
        .deploy(@calldata)
        .expect('failed to deploy contract');

    let counter = ICounterDispatcher { contract_address };

    let ownable = IOwnableDispatcher { contract_address };

    (counter, ownable)
}

#[test]
fn test_counter_deployment() {
    let (counter, ownable) = _deploy_(ZERO_COUNT);

    // count 1
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');

    assert(ownable.owner() == OWNER(), 'owner not set');
}
