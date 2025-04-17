use contracts::Counter::{ICounterDispatcher, ICounterDispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::{ContractAddress};

// Real contract address deployed on Sepolia
const OWNER: felt252 = 0x02dA5254690b46B9C4059C25366D1778839BE63C142d899F0306fd5c312A5918;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract_class = declare(name).unwrap().contract_class();
    let init_value: u32 = 10;
    let mut calldata = array![];
    calldata.append_serde(init_value);
    calldata.append_serde(OWNER);
    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
    contract_address
}
#[test]
fn contract() {
    let contract_address = deploy_contract("Counter");

    let dispatcher = ICounterDispatcher { contract_address };

    let init_value = dispatcher.get_counter();

    let expected_value: u32 = 10;

    assert(init_value == expected_value, 'Should have the right value');
    dispatcher.increase_counter();

    let new_value = dispatcher.get_counter();

    let expected_value: u32 = 11;

    assert(new_value == expected_value, 'Should have the right value');

    dispatcher.decrease_counter();
    dispatcher.decrease_counter();
    dispatcher.decrease_counter();

    let new_value = dispatcher.get_counter();

    let expected_value: u32 = 8;

    assert(new_value == expected_value, 'Should have the right value');

    dispatcher.reset_counter();

    let new_value = dispatcher.get_counter();

    let expected_value: u32 = 0;    
    
    assert(new_value == expected_value, 'Should have the right value');
}

