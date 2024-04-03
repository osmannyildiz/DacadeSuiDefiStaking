module stakingContract::reward {
    // === Imports ===
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};
    use sui::balance::{Self, Balance};
    use sui::clock::{Clock, timestamp_ms};
    use sui::sui::{SUI};
    use std::debug;
    use stakingContract::mnt::{MNT, CapWrapper, mint};
    use stakingContract::account::{Self, Pool, Account};

    friend stakingContract::staking;

    // === Constants ===
    const SCALAR: u128 = 1_000_000_000;
    const YEAR: u128 = 31556926; // Number of milliseconds in a year

    // === Errors ===
    const ERROR_INSUFFICIENT_COIN: u64 = 0;
    const ERROR_INVALID_QUANTITY: u64 = 1;

    // === Functions ===
    public(friend) fun calculate_reward(pool: &mut Pool, clock: &Clock, owner: address): u64 {
        let interest = account::get_interest(pool);
        let account = account::borrow_mut_account(pool, owner, clock);
        let duration = timestamp_ms(clock) - account::get_duration(account);
        let balance = account::get_balance(account);
        let reward = ((balance as u128) * (duration as u128) * interest) / (YEAR * SCALAR);
        account::set_account(account, timestamp_ms(clock), reward as u64);
        account::get_rewards(account)
    }

    public(friend) fun calculate_and_withdraw_reward(pool: &mut Pool, clock: &Clock, owner: address): Coin<MNT> {
        let reward = calculate_reward(pool, clock, owner);
        assert!(reward > 0, ERROR_INVALID_QUANTITY);
        let account = account::borrow_mut_account(pool, owner, clock);
        account::set_reward(account);
        mint(reward, sender(ctx))
    }
}