// Import necessary components from the StarkNet library.
use starknet::ContractAddress;
use starknet::{SyscallResultTrait, ContractAddress, syscalls};

// Define the ICounter interface, which contains functions for interacting with the counter.
#[starknet::interface]
trait ICounter<TContractState> {
    // Function to get the current value of the counter.
    fn get_counter(self: @TContractState) -> u32;
    
    // Function to increase the value of the counter.
    fn increase_counter(ref self: TContractState);
}

// Define the IKillSwitch interface, which contains functions related to the kill switch mechanism.
#[starknet::interface]
trait IKillSwitch<TContractState> {
    // Function to check if the kill switch is active.
    fn is_active(self: @TContractState) -> bool;
}

// Define the Counter contract module.
#[starknet::contract]
mod Counter {
    // Import necessary components.
    use starknet::{ContractAddress};
    use super::{ICounter};
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait}; // Import the kill switch dispatcher interface.
    use openzeppelin::access::ownable::OwnableComponent; // Import the Ownable component from OpenZeppelin.

    // Define the Ownable component for access control.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Implement the Ownable interface for this contract.
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    // Implement the internal Ownable functionality.
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Define the storage structure for the contract.
    #[storage]
    struct Storage {    
        counter: u32, // Storage for the counter value.
        kill_switch: ContractAddress, // Storage for the kill switch contract address.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage // Storage for the Ownable component.
    }

    // Define the constructor for initializing the contract.
    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u32, kill_switch: ContractAddress) {
        self.counter.write(initial_counter); // Initialize the counter with the provided value.
        self.kill_switch.write(kill_switch); // Initialize the kill switch contract address.
        self.ownable.initializer(initial_owner); // Initialize the Ownable component with the initial owner.
    }

    // Define events for the contract.
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased, // Event for when the counter is increased.
        OwnableEvent: OwnableComponent::Event, // Event for Ownable component actions.
    }

    // Define the structure for the CounterIncreased event.
    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        counter: u32 // The new value of the counter.
    }

    // Implement the ICounter interface for the Counter contract.
    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        // Function to get the current value of the counter.
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read() // Return the current counter value.
        }

        // Function to increase the counter value.
        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner(); // Ensure only the owner can call this function.
            
            // Check if the kill switch contract is active.
            if (IKillSwitchDispatcher { contract_address: self.kill_switch.read() }).is_active() {
                panic!("Kill Switch is active"); // Panic if the kill switch is active.
            }
                
            let current_counter = self.counter.read(); // Read the current counter value.
            self.counter.write(current_counter + 1); // Increment the counter value.
            self.emit(CounterIncreased { counter: self.counter.read() }); // Emit the CounterIncreased event.
        }
    }
}
