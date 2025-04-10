#[starknet::interface]
pub trait ICounter<TContractState>{
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(self: @TContractState);
    fn decrease_counter(self: @TContractState);
    fn reset_counter(self: @TContractState);
}

#[starknet::contract]
pub mod Counter {

    #[storage]
    pub struct Storage {
        counter: u32
    }

    #[constructor]
    pub fn constructor(ref self: ContractState, init_value: u32) {
        self.counter.write(init_value);
    }

    #[event]
    #[derive[Drop, starknet::Event]]
    pub enum Event {
        Increased::Increased{
            account: ContractAddress,
        }
    }

    pub enum Error{
        const EMPTY_COUNTER: felt252 = 'Decreasing Empty Counter';
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(self: @ContractState) {
            let new_value = self.counter.read() + 1;
            self.counter.write(new_value);
            // event
            self.emit(Increased{account: get_caller_address(), value: new_value});
        }

        fn decrease_counter(self: @ContractState) {
            let old_value = self.counter.read();
            assert!(old_value > 0, Error::EMPTY_COUNTER);
            
        }

        fn reset_counter(self: @ContractState) {
            self.counter.write(0);
        }
    }

}