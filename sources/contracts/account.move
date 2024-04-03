module stakingContract::account {
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
    use sui::event;
    use sui::transfer;

    // === Errors ===
    const ERROR_INSUFFICIENT_COIN: u64 = 0;
    const ERROR_INVALID_QUANTITY: u64 = 1;
    const ERROR_ACCOUNT_NOT_FOUND: u64 = 2;

    // === Constants ===
    friend stakingContract::reward;
    friend stakingContract::staking;
    friend stakingContract::admin;

    // === Structs ===
    struct Account has key, store {
        id: UID,
        balance: Balance<SUI>,
        rewards: u64,
        duration: u64,
        owner: address
    }

    struct AccountCap has key, store {
        id: UID,
        owner: address
    }

    // Protocol pool where users can stake SUI
    struct Pool has key, store {
        id: UID,
        account_balances: Table<address, Account>,
        interest: u128,
        total_staked: u64
    }

    // === Events ===
    struct AccountCreatedEvent has copy, drop {
        account_id: address,
        owner: address
    }

    struct StakeEvent has copy, drop {
        staker: address,
        amount: u64
    }

    struct UnstakeEvent has copy, drop {
        staker: address,
        amount: u64
    }

    // === Public Functions ===
    public fun get_duration(account: &Account): u64 {
        account.duration
    }

    public fun get_balance(account: &Account): u64 {
        balance::value(&account.balance)
    }

    public fun get_rewards(account: &Account): u64 {
        account.rewards
    }

    public fun get_account_cap(account: &AccountCap): address {
        account.owner
    }

    public fun borrow_pool(pool: &Pool): &Pool {
        pool
    }

    public fun get_interest(pool: &Pool): u128 {
        pool.interest
    }

    public fun get_total_staked(pool: &Pool): u64 {
        pool.total_staked
    }

    public(friend) fun borrow_mut_pool(pool: &mut Pool): &mut Pool {
        pool
    }

    public(friend) fun new_interest(pool: &mut Pool, num: u128) {
        pool.interest = num;
    }

    public fun set_account(account: &mut Account, duration_: u64, reward: u64) {
        account.duration = duration_;
        account.rewards = account.rewards + reward;
    }

    public fun set_reward(account: &mut Account) {
        account.rewards = 0;
    }

    public fun account_owner(account_cap: &AccountCap): address {
        account_cap.owner
    }

    public(friend) fun create_account(ctx: &mut TxContext): AccountCap {
        let id = object::new(ctx);
        let owner = object::uid_to_address(&id);
        let account = Account {
            id,
            balance: balance::zero(),
            rewards: 0,
            duration: timestamp_ms(&Clock {}),
            owner
        };
        table::add(&mut borrow_mut_pool(Pool::new(ctx)).account_balances, owner, account);
        event::emit(AccountCreatedEvent { account_id: owner, owner });
        AccountCap { id, owner }
    }

    // create new pool
    public fun new(ctx: &mut TxContext): Pool {
        Pool {
            id: object::new(ctx),
            account_balances: table::new(ctx),
            interest: 10,
            total_staked: 0
        }
    }

    // return the user balance and reward
    public fun account_balance(pool: &Pool, owner: address): (u64, u64) {
        let account = table::borrow(&pool.account_balances, owner);
        if (account == ()) {
            return (0, 0)
        };
        let avail_balance = balance::value(&account.balance);
        let reward = account.rewards;
        (avail_balance, reward)
    }

    public(friend) fun borrow_mut_account(
        pool: &mut Pool,
        owner: address,
        clock: &Clock,
    ): &mut Account {
        if (!table::contains(&pool.account_balances, owner)) {
            table::add(
                &mut pool.account_balances,
                owner,
                Account {
                    id: object::new(&mut TxContext {}),
                    balance: balance::zero(),
                    rewards: 0,
                    duration: timestamp_ms(clock),
                    owner
                }
            );
        };
        table::borrow_mut(&mut pool.account_balances, owner)
    }

    public(friend) fun borrow_mut_account_balance(
        pool: &mut Pool,
        owner: address,
        clock: &Clock,
    ): &mut Balance<SUI> {
        if (!table::contains(&pool.account_balances, owner)) {
            table::add(
                &mut pool.account_balances,
                owner,
                Account {
                    id: object::new(&mut TxContext {}),
                    balance: balance::zero(),
                    rewards: 0,
                    duration: timestamp_ms(clock),
                    owner
                }
            );
        };
        let account = table::borrow_mut(&mut pool.account_balances, owner);
        &mut account.balance
    }

    // === Stake and Unstake Functions ===
    public entry fun stake(pool: &mut Pool, coin: Coin<SUI>, ctx: &mut TxContext) {
        let staker = transfer::withdraw_all_coins(coin, ctx);
        let staked_amount = balance::value(&staker);
        if (staked_amount == 0) {
            abort ERROR_INVALID_QUANTITY
        };

        let account = borrow_mut_account(pool, transfer::sender(ctx), &Clock {});
        balance::join(&mut account.balance, staker);
        pool.total_staked = pool.total_staked + staked_amount;

        event::emit(StakeEvent { staker: transfer::sender(ctx), amount: staked_amount });
    }

    public entry fun unstake(pool: &mut Pool, amount: u64, ctx: &mut TxContext) {
        let account = borrow_mut_account(pool, transfer::sender(ctx), &Clock {});
        let account_balance = balance::value(&account.balance);
        if (account_balance < amount) {
            abort ERROR_INSUFFICIENT_COIN
        };

        let staked_coin = balance::split(&mut account.balance, amount);
        transfer::transfer(staked_coin, transfer::sender(ctx));
        pool.total_staked = pool.total_staked - amount;

        event::emit(UnstakeEvent { staker: transfer::sender(ctx), amount });
    }
}