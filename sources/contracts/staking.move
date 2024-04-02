module stakingContract::staking {
    // === Imports ===
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext, sender};
    use sui::coin::{Self, Coin};
    use sui::table;
    use sui::balance::{Self, Balance};
    use sui::clock::{Clock, timestamp_ms};
    use sui::sui::SUI;
    use stakingContract::mnt::{MNT, CapWrapper, mint};
    use stakingContract::account::{Account, AccountCap, Pool};
    use stakingContract::reward::{calculate_reward, calculate_reward_withdraw};

    // === Errors ===
    const ERROR_INSUFFICIENT_COIN: u64 = 0;
    const ERROR_INVALID_QUANTITY: u64 = 1;

    // === Public Functions ===

    /// Creates a new account for the user and transfers the AccountCap to the sender.
    public fun new_account(ctx: &mut TxContext) {
        transfer::public_transfer(account::create_account(ctx), sender(ctx))
    }

    /// Deposits SUI coins into the staking pool for the specified account.
    /// `pool`: The staking pool to deposit into.
    /// `coin`: The SUI coins to be deposited.
    /// `clock`: The clock object used for reward calculation.
    /// `account_cap`: The AccountCap of the account to deposit for.
    public fun deposit(pool: &mut Pool, coin: Coin<SUI>, clock: &Clock, account_cap: &AccountCap) {
        let quantity = coin::value(&coin);
        assert!(quantity != 0, ERROR_INSUFFICIENT_COIN);
        increase_user_available_balance(pool, account::account_owner(account_cap), coin::into_balance(coin), clock);
    }

    /// Withdraws SUI coins from the staking pool for the specified account.
    /// Returns the withdrawn SUI coins.
    /// `pool`: The staking pool to withdraw from.
    /// `account_cap`: The AccountCap of the account to withdraw for.
    /// `clock`: The clock object used for reward calculation.
    /// `quantity`: The amount of SUI coins to withdraw.
    /// `ctx`: The transaction context.
    public fun withdraw(
        pool: &mut Pool,
        account_cap: &AccountCap,
        clock: &Clock,
        quantity: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        assert!(quantity > 0, ERROR_INVALID_QUANTITY);
        coin::from_balance(decrease_user_available_balance(pool, account_cap, quantity, clock), ctx)
    }

    /// Withdraws the earned rewards for the specified account.
    /// Returns the withdrawn MNT coins representing the rewards.
    /// `pool`: The staking pool to withdraw rewards from.
    /// `account_cap`: The AccountCap of the account to withdraw rewards for.
    /// `capwrapper`: The CapWrapper used for minting MNT coins.
    /// `clock`: The clock object used for reward calculation.
    /// `ctx`: The transaction context.
    public fun withdraw_reward(
        pool: &mut Pool,
        account_cap: &AccountCap,
        capwrapper: &mut CapWrapper,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<MNT> {
        let rewards = calculate_reward_withdraw(pool, clock, account::account_owner(account_cap));
        mint(capwrapper, rewards, ctx)
    }

    // === Helper Functions ===

    /// Increases the available balance of the specified account in the staking pool.
    /// `pool`: The staking pool.
    /// `owner`: The address of the account owner.
    /// `quantity`: The amount of SUI coins to add to the available balance.
    /// `clock`: The clock object used for reward calculation.
    fun increase_user_available_balance(
        pool: &mut Pool,
        owner: address,
        quantity: Balance<SUI>,
        clock: &Clock
    ) {
        calculate_reward(pool, clock, owner);
        let account = account::borrow_mut_account_balance(pool, owner, clock);
        balance::join(account, quantity);
    }

    /// Decreases the available balance of the specified account in the staking pool.
    /// Returns the split Balance representing the withdrawn amount.
    /// `pool`: The staking pool.
    /// `account_cap`: The AccountCap of the account to withdraw from.
    /// `quantity`: The amount of SUI coins to withdraw from the available balance.
    /// `clock`: The clock object used for reward calculation.
    fun decrease_user_available_balance(
        pool: &mut Pool,
        account_cap: &AccountCap,
        quantity: u64,
        clock: &Clock
    ): Balance<SUI> {
        calculate_reward(pool, clock, account::account_owner(account_cap));
        let account = account::borrow_mut_account_balance(pool, account::account_owner(account_cap), clock);
        balance::split(account, quantity)
    }
}
