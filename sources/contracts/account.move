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

   // === Errors ===
   const ERROR_INSUFFICENT_COIN: u64 = 0;
   const ERROR_INVALID_QUANTITIY: u64 = 1;

   // === Constants ===
   friend stakingContract::reward;
   friend stakingContract::staking;
   friend stakingContract::admin;

   // === Structs ===
   struct Account has store {
       balance: Balance<SUI>,
       rewards: u64,
       duration: u64
   }

   struct AccountCap has key, store {
       id: UID,
       owner: address
   }

   struct Pool has key, store {
       id: UID,
       account_balances: Table<address, Account>,
       interest: u128
   }

   // === Utility Functions ===
   fun account_duration(account: &Account): u64 {
       &account.duration
   }

   fun account_balance(account: &Account): u64 {
       balance::value(&account.balance)
   }

   fun account_rewards(account: &Account): u64 {
       account.rewards
   }

   fun account_cap_owner(account_cap: &AccountCap): address {
       account_cap.owner
   }

   fun borrow_pool(pool: &Pool): &Pool {
       pool
   }

   fun pool_interest(pool: &Pool): u128 {
       pool.interest
   }

   fun borrow_mut_pool(pool: &mut Pool): &mut Pool {
       pool
   }

   fun new_interest(pool: &mut Pool, num: u128) {
       pool.interest = num;
   }

   fun set_account(account: &mut Account, duration_: u64, reward: u64) {
       account.duration = duration_;
       account.rewards = account.rewards + reward;
   }

   fun set_reward(account: &mut Account) {
       account.rewards = 0;
   }

   // === Entry Functions ===
   public fun create_account(ctx: &mut TxContext): AccountCap {
       AccountCap {
           id: object::new(ctx),
           owner: object::uid_to_address(&id)
       }
   }

   public fun new(ctx: &mut TxContext): Pool {
       Pool {
           id: object::new(ctx),
           account_balances: table::new(ctx),
           interest: 10
       }
   }

   public fun account_balance_and_reward(
       pool: &Pool,
       owner: address
   ): (u64, u64) {
       if (!table::contains(&pool.account_balances, owner)) {
           return (0, 0)
       };
       let account = table::borrow(&pool.account_balances, owner);
       (account_balance(&account), account_rewards(&account))
   }

   public(friend) fun borrow_mut_account_and_balance(
       pool: &mut Pool,
       owner: address,
       clock: &Clock,
   ): (&mut Account, &mut Balance<SUI>) {
       if (!table::contains(&pool.account_balances, owner)) {
           table::add(
               &mut pool.account_balances,
               owner,
               Account {
                   balance: balance::zero(),
                   rewards: 0,
                   duration: timestamp_ms(clock)
               }
           );
       };
       let account = table::borrow_mut(&mut pool.account_balances, owner);
       (account, &mut account.balance)
   }
}
