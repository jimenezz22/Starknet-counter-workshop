use starknet::ContractAddress;
use starknet::{SyscallResultTrait, ContractAddress, syscalls};

#[starknet::interface]
trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}

#[starknet::interface]
trait IKillSwitch<TContractState> {
    fn is_active(self: @TContractState) -> bool;
}

#[starknet::contract]
mod Counter {
    use starknet::{ContractAddress};
    use super::{ICounter};
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent; // Import the kill switch interface

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {    
        counter: u32,
        kill_switch: ContractAddress, //Add a field for the kill switch contract
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u32, kill_switch: ContractAddress) {
        self.counter.write(initial_counter);
        self.kill_switch.write(kill_switch); //Initialize the kill switch contract
        self.ownable.initializer(initial_owner);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        counter: u32
    }

    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            let is_active = self.kill_switch.read().is_active(); //check if the contract is active

            if (IKillSwitchDispatcher { contract_address: self.kill_switch.read()}).is_active() { //Check if the kill switch is active
                panic!("Kill Switch is active");  //If the kill switch is active, panic
            }
                
            let current_counter = self.counter.read();
            self.counter.write(current_counter + 1);
            self.emit(CounterIncreased { counter: self.counter.read() })
        }
    }
}