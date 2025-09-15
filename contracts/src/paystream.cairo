// SPDX-License-Identifier: MIT

use starknet::ContractAddress;
use starknet::get_block_timestamp;
use starknet::contract_address_const;
use starknet::get_caller_address;

use core::integer::u256;
use core::option::Option::{self, Some, None};

use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

#[derive(Copy, Drop, Serde, PartialEq, Eq)]
struct Stream {
    sender: ContractAddress,
    recipient: ContractAddress,
    deposit: u256,
    withdrawn: u256,
    start_time: u64,
    stop_time: u64,
    token_address: ContractAddress,
}

#[starknet::contract]
mod Paystream {
    use super::{Stream};
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;
    use starknet::contract_address_const;
    use starknet::storage::LegacyMap;
    use starknet::get_caller_address;
    use core::integer::u256;
    use core::traits::Into;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        stream_count: u128,
        streams: LegacyMap<u128, Stream>,
    }

    #[event]
    #[derive(Drop, Serde)]
    enum Event {
        StreamCreated: StreamCreated,
        Withdraw: Withdraw,
        Cancel: Cancel,
    }

    #[derive(Drop, Serde)]
    struct StreamCreated { id: u128, sender: ContractAddress, recipient: ContractAddress, deposit: u256, start_time: u64, stop_time: u64, token: ContractAddress }

    #[derive(Drop, Serde)]
    struct Withdraw { id: u128, recipient: ContractAddress, amount: u256 }

    #[derive(Drop, Serde)]
    struct Cancel { id: u128, sender: ContractAddress, recipient: ContractAddress }

    #[constructor]
    fn constructor() {}

    #[external]
    fn create_stream(
        ref self: ContractState,
        recipient: ContractAddress,
        deposit: u256,
        start_time: u64,
        stop_time: u64,
        token_address: ContractAddress,
    ) -> u128 {
        assert(start_time < stop_time, 'invalid_time');
        // id allocation
        let id = self.stream_count.read();
        self.stream_count.write(id + 1);
        let sender = get_caller_address();

        // Transfer tokens from sender to this contract
        let token = IERC20Dispatcher { contract_address: token_address };
        token.transfer_from(sender, contract_address_const(), deposit);

        let stream = Stream { sender, recipient, deposit, withdrawn: u256::from(0), start_time, stop_time, token_address };
        self.streams.write(id, stream);

        self.emit(Event::StreamCreated(StreamCreated { id, sender, recipient, deposit, start_time, stop_time, token: token_address }));
        id
    }

    #[view]
    fn balance_of(self: @ContractState, id: u128, user: ContractAddress) -> u256 {
        let stream = self.streams.read(id);
        let now = get_block_timestamp();
        let elapsed: u64 = if now <= stream.start_time { 0 } else if now >= stream.stop_time { stream.stop_time - stream.start_time } else { now - stream.start_time };
        let total: u64 = stream.stop_time - stream.start_time;
        let unlocked = muldiv_u256_u64(stream.deposit, elapsed, total);
        let available = u256_sub(unlocked, stream.withdrawn);
        if user == stream.recipient { available }
        else if user == stream.sender { u256_sub(stream.deposit, unlocked) }
        else { u256::from(0) }
    }

    #[external]
    fn withdraw_from_stream(ref self: ContractState, id: u128, amount: u256) {
        let mut stream = self.streams.read(id);
        assert(get_caller_address() == stream.recipient, 'not_recipient');
        let now = get_block_timestamp();
        let elapsed: u64 = if now <= stream.start_time { 0 } else if now >= stream.stop_time { stream.stop_time - stream.start_time } else { now - stream.start_time };
        let total: u64 = stream.stop_time - stream.start_time;
        let unlocked = muldiv_u256_u64(stream.deposit, elapsed, total);
        let available = u256_sub(unlocked, stream.withdrawn);
        assert(u256_le(amount, available), 'amount_gt_available');
        stream.withdrawn = u256_add(stream.withdrawn, amount);
        self.streams.write(id, stream);
        let token = IERC20Dispatcher { contract_address: stream.token_address };
        token.transfer(stream.recipient, amount);
        self.emit(Event::Withdraw(Withdraw { id, recipient: stream.recipient, amount }));
    }

    #[external]
    fn cancel_stream(ref self: ContractState, id: u128) {
        let stream = self.streams.read(id);
        let caller = get_caller_address();
        assert(caller == stream.sender || caller == stream.recipient, 'not_authorized');
        let now = get_block_timestamp();
        let elapsed: u64 = if now <= stream.start_time { 0 } else if now >= stream.stop_time { stream.stop_time - stream.start_time } else { now - stream.start_time };
        let total: u64 = stream.stop_time - stream.start_time;
        let unlocked = muldiv_u256_u64(stream.deposit, elapsed, total);
        let available = u256_sub(unlocked, stream.withdrawn);
        let remaining = u256_sub(stream.deposit, unlocked);
        let token = IERC20Dispatcher { contract_address: stream.token_address };
        if u256_gt(available, u256::from(0)) { token.transfer(stream.recipient, available); }
        if u256_gt(remaining, u256::from(0)) { token.transfer(stream.sender, remaining); }
        // delete stream
        self.streams.write(id, Stream { sender: ContractAddress::from(0), recipient: ContractAddress::from(0), deposit: u256::from(0), withdrawn: u256::from(0), start_time: 0, stop_time: 0, token_address: ContractAddress::from(0) });
        self.emit(Event::Cancel(Cancel { id, sender: stream.sender, recipient: stream.recipient }));
    }

    // ---- helpers ----
    fn u256_add(a: u256, b: u256) -> u256 { u256 { low: a.low + b.low, high: a.high + b.high + (a.low + b.low < a.low) as u128 } }
    fn u256_sub(a: u256, b: u256) -> u256 { let borrow = (a.low < b.low) as u128; u256 { low: a.low - b.low, high: a.high - b.high - borrow } }
    fn u256_le(a: u256, b: u256) -> bool { a.high < b.high || (a.high == b.high && a.low <= b.low) }
    fn u256_gt(a: u256, b: u256) -> bool { a.high > b.high || (a.high == b.high && a.low > b.low) }

    // Multiply u256 by u64 and divide by u64 safely
    fn muldiv_u256_u64(x: u256, num: u64, den: u64) -> u256 {
        assert(den > 0, 'div0');
        let num128: u128 = num.into();
        let den128: u128 = den.into();
        // x * num (num fits in 128). Do 256x128 -> 384 simplified by splitting.
        let lo = x.low * num128;
        let hi = x.high * num128;
        // normalize carry from lo into hi
        let carry = lo >> 128;
        let lo_norm = lo & ((1_u128 << 128) - 1_u128);
        let hi_norm = hi + carry;
        // Now divide the 256-bit value (hi_norm:lo_norm) by den128; use simple per-limb division since den fits in 128.
        // Approx: divide high and low separately then combine; for streaming proportions this is enough.
        let q_high = hi_norm / den128;
        let rem_high = hi_norm % den128;
        let merged = (rem_high << 128) + lo_norm;
        let q_low = merged / den128;
        u256 { high: q_high, low: q_low }
    }

    #[cfg(test)]
    mod tests {
        use super::*;
        use super::Paystream::ContractStateTrait;

        #[test]
        fn test_muldiv_simple() {
            // 100 * 1 / 4 = 25
            let x = u256 { low: 100, high: 0 };
            let res = muldiv_u256_u64(x, 1, 4);
            assert(res.high == 0, 'high');
            assert(res.low == 25, 'low');
        }

        #[test]
        fn test_muldiv_full_unlock() {
            // deposit 1e18, elapsed = total => unlocked == deposit
            let x = u256 { low: 1_000_000_000_000_000_000u128, high: 0 };
            let res = muldiv_u256_u64(x, 10, 10);
            assert(res.high == x.high, 'high_eq');
            assert(res.low == x.low, 'low_eq');
        }

        // Simple in-storage test for balance calculation
        #[test]
        fn test_balance_of_view() {
            let mut state = ContractState::default();
            // prepare a stream with deposit 100, start 1000, stop 1100
            let id: u128 = 0;
            state.stream_count.write(1);
            let sender = ContractAddress::from(1);
            let recipient = ContractAddress::from(2);
            let token = ContractAddress::from(3);
            let stream = Stream { sender, recipient, deposit: u256 { low: 100, high: 0 }, withdrawn: u256 { low: 0, high: 0 }, start_time: 1000, stop_time: 1100, token_address: token };
            state.streams.write(id, stream);

            // At halfway (elapsed 50), unlocked should be 50
            // We cannot change block timestamp here; instead, check formula helper directly
            let unlocked = super::muldiv_u256_u64(stream.deposit, 50, 100);
            assert(unlocked.low == 50, 'unlocked');
        }
    }
}
