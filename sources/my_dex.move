module my_dex::mydex {
    use sui::coin::{Self, Coin, into_balance};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use std::option;
    use sui::event;

    /// Custom token type to represent MYDEX
    public struct MYDEX has drop {}

    /// Liquidity Pool that holds balances of both tokens
    public struct LiquidityPool has key {
        id: UID,
        sui_balance: Balance<sui::sui::SUI>,
        mydex_balance: Balance<MYDEX>,
        owner: address,
    }

    /// Event to log pool creation
    public struct PoolCreated has copy, drop, store {
        owner: address,
        sui_amount: u64,
        mydex_amount: u64,
    }

    /// Token deployment and minting
    fun init(witness: MYDEX, ctx: &mut TxContext) {
        let (mut treasury, metadata) = coin::create_currency(
            witness,
            9,
            b"MYDEX",
            b"MY DEX TOKEN",
            b"This is custom MY DEX token",
            option::some(url::new_unsafe_from_bytes(
                b"https://silver-blushing-woodpecker-143.mypinata.cloud/ipfs/Qmed2qynTAszs9SiZZpf58QeXcNcYgPnu6XzkD4oeLacU4"
            )),
            ctx
        );

        transfer::public_freeze_object(metadata);

        let initial_amount = 10_000_000_000_000_000;
        let deployer = tx_context::sender(ctx);
        coin::mint_and_transfer(&mut treasury, initial_amount, deployer, ctx);
        transfer::public_transfer(treasury, deployer);
    }

    /// Create a persistent liquidity pool with both token balances
    public entry fun create_pool(
        mydex_payment: Coin<MYDEX>, 
        sui_payment: Coin<sui::sui::SUI>, 
        ctx: &mut TxContext
    ) {
        let sui_amount = coin::value(&sui_payment);
        let mydex_amount = coin::value(&mydex_payment);
        let sui_balance = into_balance(sui_payment);
        let mydex_balance = into_balance(mydex_payment);
        let owner = tx_context::sender(ctx);
        let id = object::new(ctx); // Needed for persistent struct with `key`

        // Emit event
        event::emit(PoolCreated {
            owner,
            sui_amount,
            mydex_amount,
        });

        let pool = LiquidityPool {
            id,
            sui_balance,
            mydex_balance,
            owner
        };
        transfer::transfer(pool, owner);
    }
}
