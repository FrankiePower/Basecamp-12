#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
    fn decrease_counter(ref self: TContractState);
    fn reset_counter(ref self: TContractState);
}

#[starknet::contract]
mod Counter {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin_access::ownable::OwnableComponent;
    use super::{ICounter};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    // #[event]
    // #[derive(Drop, starknet::Event)]
    // pub enum Event {
    //     #[flat]
    //     Increased: Increased,
    //     Decreased: Decreased,
    //     OwnableEvent: OwnableComponent::Event,
    // }

    // #[derive(Drop, starknet::Event)]
    // pub struct Increased {
    //     #[key]
    //     account: ContractAddress,
    //     #[key]
    //     value: u32,
    // }

    // #[derive(Drop, starknet::Event)]
    // pub struct Decreased {
    //     #[key]
    //     account: ContractAddress,
    //     #[key]
    //     value: u32,
    // }

    pub mod Error {
        const EMPTY_COUNTER: felt252 = 'Decreasing Empty Counter';
    }

    #[constructor]
    fn constructor(ref self: ContractState, init_value: u32) {
        self.counter.write(init_value);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let new_value = self.counter.read() + 1;
            self.counter.write(new_value);
            // event
        // self.emit(Increased { account: get_caller_address(), value: new_value });
        }

        fn decrease_counter(ref self: ContractState) {
            let old_value = self.counter.read();
            assert(old_value > 0, Error::EMPTY_COUNTER);
        }

        fn reset_counter(ref self: ContractState) {
            // only owner can reset
            self.counter.write(0);
        }
    }
}

