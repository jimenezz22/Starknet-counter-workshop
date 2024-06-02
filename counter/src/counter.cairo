use starknet::ContractAddress;

#[starknet::interface]
trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}

#[starknet::contract]
mod Counter {
    use starknet::{ContractAddress};
    use super::{ICounter};
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait}; // Import the kill switch interface

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: IKillSwitchDispatcher, // Add the kill switch dispatcher to the storage
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u32, kill_switch: ContractAddress) {
        self.counter.write(initial_counter);
        self.kill_switch.write(IKillSwitchDispatcher { contract_address: kill_switch_address }); // Initialize the kill switch dispatcher
    }

    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let counter = self.counter.read();
            self.counter.write(counter + 1);
        }
    }
}