module stakingContract::reward {
    // === Imports ===
    use sui::object;
    use sui::tx_context::TxContext;
    use sui::coin;
    use sui::table;
    use sui::balance;
    use sui::clock::{Clock, timestamp_ms};
    use sui::sui::SUI;
    use stakingContract::mnt::{MNT, CapWrapper, mint};
    use stakingContract::account::{Pool, Account};

    friend stakingContract::staking;

    // === Constants ===
    /// SCALAR is a constant used for conversion between different units.
    const SCALAR: u128 = 1_000_000_000;
    /// YEAR is the number of milliseconds in a year, used for calculating annual rewards.
    const YEAR: u128 = 31556926;

    // === Errors ===
    const ERROR_INSUFFICIENT_COIN: u64 = 0;
    const ERROR_INVALID_QUANTITY: u64 = 1;

    // === Functions ===

    /// Calculates the reward earned by the account owner based on the staked balance and duration.
    /// Returns the calculated reward amount.
    /// `pool`: The staking pool from which the reward is being calculated.
    /// `clock`: The clock object used to calculate the duration.
    /// `owner`: The address of the account owner.
    public(friend) fun calculate_reward(pool: &mut Pool, clock: &Clock, owner: address): u64 {
        let account = account::borrow_mut_account(pool, owner, clock);
        let duration = timestamp_ms(clock) - account::get_duration(account);
        let balance = account::get_balance(account);
        let reward = (balance as u128) * (duration as u128) / YEAR;

        account::set_account(account, timestamp_ms(clock), reward as u64);
        account::get_rewards(account)
    }

    /// Calculates the reward earned by the account owner and withdraws it from the staking pool.
    /// Returns the withdrawn reward amount.
    /// `pool`: The staking pool from which the reward is being withdrawn.
    /// `clock`: The clock object used to calculate the duration.
    /// `owner`: The address of the account owner.
    public(friend) fun calculate_reward_withdraw(pool: &mut Pool, clock: &Clock, owner: address): u64 {
        let account = account::borrow_mut_account(pool, owner, clock);
        let duration = timestamp_ms(clock) - account::get_duration(account);
        let balance = account::get_balance(account);
        let reward = (balance as u128) * (duration as u128) / YEAR;

        account::set_account(account, timestamp_ms(clock), reward as u64);
        let mint = account::get_rewards(account);
        assert!(mint > 0, ERROR_INVALID_QUANTITY);

        account::set_reward(account);
        mint
    }
}
