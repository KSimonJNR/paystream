// SPDX-License-Identifier: MIT
// Paystream contract for StarkNet (Cairo 1.0)

%lang starknet

from starkware::starknet::contract_address import ContractAddress
from starkware::starknet::storage import Storage
from starkware::starknet::syscalls import get_block_timestamp
from openzeppelin::token::erc20::interface::IERC20

@storage_var
func stream_count() -> (res: felt252) {}

@storage_var
func streams(stream_id: felt252) -> (
    sender: ContractAddress,
    recipient: ContractAddress,
    deposit: Uint256,
    withdrawn: Uint256,
    start_time: u64,
    stop_time: u64,
    token_address: ContractAddress
) {}

struct Stream {
    sender: ContractAddress,
    recipient: ContractAddress,
    deposit: Uint256,
    withdrawn: Uint256,
    start_time: u64,
    stop_time: u64,
    token_address: ContractAddress
}

@external
func create_stream(
    recipient: ContractAddress,
    deposit: Uint256,
    start_time: u64,
    stop_time: u64,
    token_address: ContractAddress
) -> (stream_id: felt252) {
    alloc_locals;
    let (current_id) = stream_count.read();
    stream_count.write(current_id + 1);
    // Transfer tokens from sender to contract
    IERC20::transferFrom(
        token_address,
        get_caller_address(),
        contract_address_const(),
        deposit
    );
    streams.write(
        current_id,
        get_caller_address(),
        recipient,
        deposit,
        Uint256(0, 0),
        start_time,
        stop_time,
        token_address
    );
    return (current_id,);
}

@view
func balance_of(stream_id: felt252, user: ContractAddress) -> (balance: Uint256) {
    let (
        sender,
        recipient,
        deposit,
        withdrawn,
        start_time,
        stop_time,
        token_address
    ) = streams.read(stream_id);
    let (now) = get_block_timestamp();
    let elapsed = if now <= start_time {
        0
    } else if now >= stop_time {
        stop_time - start_time
    } else {
        now - start_time
    };
    let total_time = stop_time - start_time;
    let unlocked = Uint256_muldiv(deposit, elapsed, total_time);
    let available = Uint256_sub(unlocked, withdrawn);
    if user == recipient {
        return (available,);
    } else if user == sender {
        let remaining = Uint256_sub(deposit, unlocked);
        return (remaining,);
    } else {
        return (Uint256(0, 0),);
    }
}

@external
func withdraw_from_stream(stream_id: felt252, amount: Uint256) {
    alloc_locals;
    let (
        sender,
        recipient,
        deposit,
        withdrawn,
        start_time,
        stop_time,
        token_address
    ) = streams.read(stream_id);
    assert get_caller_address() == recipient;
    let (now) = get_block_timestamp();
    let elapsed = if now <= start_time {
        0
    } else if now >= stop_time {
        stop_time - start_time
    } else {
        now - start_time
    };
    let total_time = stop_time - start_time;
    let unlocked = Uint256_muldiv(deposit, elapsed, total_time);
    let available = Uint256_sub(unlocked, withdrawn);
    assert Uint256_le(amount, available) == 1;
    let new_withdrawn = Uint256_add(withdrawn, amount);
    streams.write(
        stream_id,
        sender,
        recipient,
        deposit,
        new_withdrawn,
        start_time,
        stop_time,
        token_address
    );
    IERC20::transfer(token_address, recipient, amount);
    return ();
}

@external
func cancel_stream(stream_id: felt252) {
    alloc_locals;
    let (
        sender,
        recipient,
        deposit,
        withdrawn,
        start_time,
        stop_time,
        token_address
    ) = streams.read(stream_id);
    let caller = get_caller_address();
    assert caller == sender || caller == recipient;
    let (now) = get_block_timestamp();
    let elapsed = if now <= start_time {
        0
    } else if now >= stop_time {
        stop_time - start_time
    } else {
        now - start_time
    };
    let total_time = stop_time - start_time;
    let unlocked = Uint256_muldiv(deposit, elapsed, total_time);
    let available = Uint256_sub(unlocked, withdrawn);
    let remaining = Uint256_sub(deposit, unlocked);
    // Pay out available to recipient
    if Uint256_gt(available, Uint256(0, 0)) == 1 {
        IERC20::transfer(token_address, recipient, available);
    }
    // Refund remaining to sender
    if Uint256_gt(remaining, Uint256(0, 0)) == 1 {
        IERC20::transfer(token_address, sender, remaining);
    }
    // Delete stream
    streams.write(
        stream_id,
        ContractAddress(0),
        ContractAddress(0),
        Uint256(0, 0),
        Uint256(0, 0),
        0,
        0,
        ContractAddress(0)
    );
    return ();
}


// Uint256 math helper functions
from openzeppelin::utils::math::uint256 import Uint256, uint256_add, uint256_sub, uint256_le, uint256_gt

// Multiply Uint256 by u64 and divide by u64 (for streaming math)
func Uint256_muldiv(amount: Uint256, elapsed: u64, total: u64) -> (res: Uint256) {
    // Convert elapsed and total to felt252 for multiplication
    let elapsed_felt: felt252 = elapsed;
    let total_felt: felt252 = total;
    let (mul_hi, mul_lo) = uint256_mul(amount, Uint256(elapsed_felt, 0));
    // Divide by total (simple version, assumes total fits in felt252)
    let (div_res, _) = uint256_div(Uint256(mul_lo, 0), Uint256(total_felt, 0));
    return (div_res,);
}

// Wrappers for OpenZeppelin uint256 math
func Uint256_add(a: Uint256, b: Uint256) -> (res: Uint256) {
    let (res) = uint256_add(a, b);
    return (res,);
}

func Uint256_sub(a: Uint256, b: Uint256) -> (res: Uint256) {
    let (res) = uint256_sub(a, b);
    return (res,);
}

func Uint256_le(a: Uint256, b: Uint256) -> (res: felt252) {
    let (res) = uint256_le(a, b);
    return (res,);
}

func Uint256_gt(a: Uint256, b: Uint256) -> (res: felt252) {
    let (res) = uint256_gt(a, b);
    return (res,);
}
