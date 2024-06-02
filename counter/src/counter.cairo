
#[starknet::interface]
trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
}

#[starknet::contract]
mod Counter {
    #[storage]
    struct Storage {
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u32) {
        self.counter.write(initial_counter);
    }

    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read(||
        }
    }
}