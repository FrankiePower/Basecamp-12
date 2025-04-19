use contracts::Counter::{
    Counter, ICounterDispatcher, ICounterDispatcherTrait, ICounterSafeDispatcher,
    ICounterSafeDispatcherTrait,
};
use openzeppelin_access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::EventSpyAssertionsTrait;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, spy_events, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress};

const ZERO_COUNT: u32 = 0;

fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

fn USER() -> ContractAddress {
    'USER'.try_into().unwrap()
}

// util deploy function
fn _deploy_(init_value: u32) -> (ICounterDispatcher, IOwnableDispatcher, ICounterSafeDispatcher) {
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

    let safe_dispatcher = ICounterSafeDispatcher { contract_address };

    (counter, ownable, safe_dispatcher)
}

#[test]
fn test_counter_deployment() {
    let (counter, ownable, _) = _deploy_(ZERO_COUNT);

    // count 1
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');

    assert(ownable.owner() == OWNER(), 'owner not set');
}

#[test]
fn test_increase_counter() {
    let (counter, _, _) = _deploy_(ZERO_COUNT);

    // count 1
    let count_1 = counter.get_counter();

    assert(count_1 == ZERO_COUNT, 'count not set');

    // increase count
    counter.increase_counter();

    // count 2
    let count_2 = counter.get_counter();

    assert(count_2 == 1, 'count not increased');
}

#[test]
fn test_emitted_increase_event() {
    let (counter, _, _) = _deploy_(ZERO_COUNT);
    let mut spy = spy_events();

    start_cheat_caller_address(counter.contract_address, USER());
    counter.increase_counter();
    stop_cheat_caller_address(counter.contract_address);

    spy
        .assert_emitted(
            @array![
                {
                    (
                        counter.contract_address,
                        Counter::Event::Increased(Counter::Increased { account: USER() }),
                    )
                },
            ],
        );

    spy
        .assert_not_emitted(
            @array![
                {
                    (
                        counter.contract_address,
                        Counter::Event::Decreased(Counter::Decreased { account: USER() }),
                    )
                },
            ],
        )
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_panic_decrease_counter() {
    let (counter, _, safe_dispatcher) = _deploy_(ZERO_COUNT);

    assert(counter.get_counter() == ZERO_COUNT, 'count not set');

    match safe_dispatcher.decrease_counter() {
        Result::Ok(_) => panic!("cannot go below zero"),
        Result::Err(panic_data) => assert(
            *panic_data.at(0) == 'Counter cannot be negative', *panic_data.at(0),
        ),
    }
}

#[should_panic(expected: 'Counter cannot be negative')]
#[test]
fn test_panic_decrease_counter() {
    let (counter, _, _) = _deploy_(ZERO_COUNT);

    assert(counter.get_counter() == ZERO_COUNT, 'count not set');

    counter.decrease_counter();
}

#[test]
fn test_successful_decrease_counter() {
    let (counter, _, _) = _deploy_(1);

    assert(counter.get_counter() == 1, 'count not set');

    counter.decrease_counter();

    assert(counter.get_counter() == 0, 'count not decreased');
}

#[test]
#[feature("safe_dispatcher")]
fn test_safe_panic_reset_counter_by_not_owner() {
    let (counter, _, safe_dispatcher) = _deploy_(5);

    assert(counter.get_counter() == 5, 'count not set');

    start_cheat_caller_address(counter.contract_address, USER());

    match safe_dispatcher.reset_counter() {
        Result::Ok(_) => panic!("cannot reset"),
        Result::Err(panic_data) => {
            //  let str_err = try_deserialize_bytearray_error(panic_data.span()).expect('wrong
            //  format');
            assert(*panic_data.at(0) == 'Caller is not the owner', *panic_data.at(0));
        },
    }
}

#[test]
fn test_successful_reset_counter() {
    let (counter, _, _) = _deploy_(5);

    assert(counter.get_counter() == 5, 'count not set');

    start_cheat_caller_address(counter.contract_address, OWNER());

    counter.reset_counter();

    stop_cheat_caller_address(counter.contract_address);

    assert(counter.get_counter() == 0, 'count not reset');
}
