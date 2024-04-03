module stakingContract::admin {
    // === Imports ===
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext, TxContext};
    use stakingContract::account::{Self, Pool};

    // === Structs ===
    struct AdminCap has key, store {
        id: UID,
        admin: address
    }

    // === Functions ===
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
            admin: tx_context::sender(ctx)
        };
        transfer::share_object(admin_cap);
    }

    public entry fun set_interest(_: &AdminCap, pool: &mut Pool, num: u128) {
        assert!(tx_context::sender(ctx) == _admin, 0);
        account::new_interest(pool, num);
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }
}