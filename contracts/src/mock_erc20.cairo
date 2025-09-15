// Minimal ERC20 mock for testing
use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::storage::LegacyMap;
use openzeppelin::utils::uint256::{Uint256, uint256_add, uint256_sub, uint256_ge};

#[derive(Copy, Drop, Serde, PartialEq, Eq)]
struct U256 {
    low: u128,
    high: u128,
}

#[starknet::contract]
mod MockERC20 {
    #[storage]
    struct Storage {
    balances: LegacyMap<ContractAddress, Uint256>,
    allowances: LegacyMap<(ContractAddress, ContractAddress), Uint256>,
    total_supply: Uint256,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[external]
    fn mint(ref self: ContractState, to: ContractAddress, amount: Uint256) {
        let bal = self.balances.read(to);
        self.balances.write(to, uint256_add(bal, amount));
        let ts = self.total_supply.read();
        self.total_supply.write(uint256_add(ts, amount));
    }

    #[external]
    fn approve(ref self: ContractState, spender: ContractAddress, amount: Uint256) {
        let owner = get_caller_address();
        self.allowances.write((owner, spender), amount);
    }

    #[external]
    fn transfer(ref self: ContractState, to: ContractAddress, amount: Uint256) {
        let from = get_caller_address();
        _transfer(self, from, to, amount);
    }

    #[external]
    fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: Uint256) {
        let spender = get_caller_address();
        let allowance = self.allowances.read((from, spender));
        assert(u256_ge(allowance, amount), 'allowance');
        self.allowances.write((from, spender), u256_sub(allowance, amount));
        _transfer(self, from, to, amount);
    }

    fn _transfer(self: @ContractState, from: ContractAddress, to: ContractAddress, amount: Uint256) {
        let from_bal = self.balances.read(from);
        assert(uint256_ge(from_bal, amount), 'bal');
        self.balances.write(from, uint256_sub(from_bal, amount));
        let to_bal = self.balances.read(to);
        self.balances.write(to, uint256_add(to_bal, amount));
    }
}
