module pocvm::vm {
    use std::error;
    use std::signer;

    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_std::table::{Self, Table};

    const STATE_ALREADY_EXISTS: u64 = 0;
    const ACCOUNT_ALREADY_EXISTS: u64 = 1;

    const ACCOUNT_NOT_FOUND: u64 = 2;
    const INSUFFICIENT_BALANCE: u64 = 3;

    struct Message has copy, drop {
        sender: u128,
        to: u128,
        value: u128,
        data: vector<u8>,
    }

    struct State has key {
        signer_capability: account::SignerCapability,
        a2e: Table<address, u128>,
        accounts: Table<u128, Account>,
    }

    struct Account has store {
        balance: u64,
        state: Table<u128, u128>,
        nonce: u128,
    }

    // init resource account and vm state
    public fun init(acct: &signer, seed: vector<u8>): address {
        let account_addr = signer::address_of(acct);
        assert!(!exists<State>(account_addr), error::already_exists(STATE_ALREADY_EXISTS));

        let (resource_signer, resource_signer_cap) = account::create_resource_account(acct, seed);
        coin::register<AptosCoin>(&resource_signer);

        move_to<State>(&resource_signer, State {
            signer_capability: resource_signer_cap,
            a2e: table::new<address, u128>(),
            accounts: table::new<u128, Account>(),
        });

        let vm_id = signer::address_of(&resource_signer);
        vm_id
    }

    public fun register(vm_id: address, acct: &signer, e_addr: u128) acquires State {
        let account_addr = signer::address_of(acct);
        let state = borrow_global_mut<State>(vm_id);
        
        let a2e = &mut state.a2e;
        assert!(!table::contains(a2e, account_addr), error::already_exists(ACCOUNT_ALREADY_EXISTS));
        
        let accounts = &mut state.accounts;
        assert!(!table::contains(accounts, e_addr), error::already_exists(ACCOUNT_ALREADY_EXISTS));

        table::add(a2e, account_addr, e_addr);
        table::add(accounts, e_addr, Account {
            balance: 0,
            state: table::new<u128, u128>(),
            nonce: 0,
        });
    }

    public fun pub_sload(vm_id: address, addr: address, slot: u128): u128 acquires State {
        let state = borrow_global<State>(vm_id);

        let a2e = &state.a2e;
        assert!(table::contains(a2e, addr), error::not_found(ACCOUNT_NOT_FOUND));

        let e_addr = table::borrow(a2e, addr);
        let acct = table::borrow(&state.accounts, *e_addr);

        sload(acct, slot)
    }

    public fun pub_sstore(vm_id: address, addr: address, slot: u128, val: u128) acquires State {
        let state = borrow_global_mut<State>(vm_id);

        let a2e = &mut state.a2e;
        assert!(table::contains(a2e, addr), error::not_found(ACCOUNT_NOT_FOUND));

        let e_addr = table::borrow(a2e, addr);
        let acct = table::borrow_mut(&mut state.accounts, *e_addr);
        sstore(acct, slot, val);
    }

    public fun pub_balance(vm_id: address, addr: address): u64 acquires State {
        let state = borrow_global<State>(vm_id);

        let a2e = &state.a2e;
        assert!(table::contains(a2e, addr), error::not_found(ACCOUNT_NOT_FOUND));

        let e_addr = table::borrow(a2e, addr);
        let acct = table::borrow(&state.accounts, *e_addr);

        balance(acct)
    }

    public fun opt_in(vm_id: address, from: address, val: u64) acquires State {
        let state = borrow_global_mut<State>(vm_id);

        let a2e = &mut state.a2e;
        assert!(table::contains(a2e, from), error::not_found(ACCOUNT_NOT_FOUND));
        
        let e_addr = table::borrow(a2e, from);
        let acct = table::borrow_mut(&mut state.accounts, *e_addr);
        acct.balance = acct.balance + val; // opt-in
    }

    public fun opt_out(vm_id: address, to: address, val: u64): signer acquires State {
        let state = borrow_global_mut<State>(vm_id);

        let a2e = &mut state.a2e;
        assert!(table::contains(a2e, to), error::not_found(ACCOUNT_NOT_FOUND));

        let e_addr = table::borrow(a2e, to);
        let acct = table::borrow_mut(&mut state.accounts, *e_addr);
        assert!(acct.balance >= val, error::invalid_state(INSUFFICIENT_BALANCE));

        acct.balance = acct.balance - val; // opt-in

        return account::create_signer_with_capability(&state.signer_capability)
    }

    fun sload(acct: &Account, slot: u128): u128 {
        if(table::contains(&acct.state, slot)) {
            *table::borrow(&acct.state, slot)
        } else {
            0
        }
    }

    fun sstore(acct: &mut Account, slot: u128, val: u128) {
        if(table::contains(&acct.state, slot)) {    
            let v = table::borrow_mut(&mut acct.state, slot);
            *v = val;
        } else {
            table::add(&mut acct.state, slot, val);
        }
    }

    fun balance(acct: &Account): u64 {
        acct.balance
    }
}