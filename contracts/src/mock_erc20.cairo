// Minimal ERC20 mock for testing
use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::storage::LegacyMap;
use core::integer::u256;

#[derive(Copy, Drop, Serde, PartialEq, Eq)]
struct U256 {
    low: u128,
    high: u128,
}

#[starknet::contract]
mod MockERC20 {
    #[storage]
    struct Storage {
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        total_supply: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[external]
    fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
        let bal = self.balances.read(to);
        self.balances.write(to, u256_add(bal, amount));
        let ts = self.total_supply.read();
        self.total_supply.write(u256_add(ts, amount));
    }

    #[external]
    fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
        let owner = get_caller_address();
        self.allowances.write((owner, spender), amount);
    }

    #[external]
    fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) {
        let from = get_caller_address();
        _transfer(self, from, to, amount);
    }

    #[external]
    fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) {
        let spender = get_caller_address();
        let allowance = self.allowances.read((from, spender));
        assert(u256_ge(allowance, amount), 'allowance');
        self.allowances.write((from, spender), u256_sub(allowance, amount));
        _transfer(self, from, to, amount);
    }

    fn _transfer(self: @ContractState, from: ContractAddress, to: ContractAddress, amount: u256) {
        let from_bal = self.balances.read(from);
        assert(u256_ge(from_bal, amount), 'bal');
        self.balances.write(from, u256_sub(from_bal, amount));
        let to_bal = self.balances.read(to);
        self.balances.write(to, u256_add(to_bal, amount));
    }

    // --- u256 helpers ---
    fn u256_add(a: u256, b: u256) -> u256 { u256 { low: a.low + b.low, high: a.high + b.high + (a.low + b.low < a.low) as u128 } }
    fn u256_sub(a: u256, b: u256) -> u256 { let borrow = (a.low < b.low) as u128; u256 { low: a.low - b.low, high: a.high - b.high - borrow } }
    fn u256_ge(a: u256, b: u256) -> bool { a.high > b.high || (a.high == b.high && a.low >= b.low) }
}
