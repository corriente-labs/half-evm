module pocvm::message {
    use std::error;
    use std::signer;
    use std::string;
    use aptos_framework::account;
    use aptos_std::event;
    use aptos_std::table::{Self, Table};

    struct State has key {
        a2e: Table<address, u128>,
        accounts: Table<u128, Account>,
    }

    struct Account has store {
        balance: u128,
        state: Table<u128, u128>
    }

    const STATE_ALREADY_EXISTS: u64 = 0;
    const ACCOUNT_ALREADY_EXISTS: u64 = 1;

    const ACCOUNT_NOT_FOUND: u64 = 2;

    public entry fun init(acct: signer) {
        let account_addr = signer::address_of(&acct);
        assert!(!exists<State>(account_addr), error::already_exists(STATE_ALREADY_EXISTS));

        move_to<State>(&acct, State {
            a2e: table::new<address, u128>(),
            accounts: table::new<u128, Account>(),
        });
    }

    public entry fun register(vm_id: address, addr: signer, e_addr: u128) acquires State {
        let account_addr = signer::address_of(&addr);
        let state = borrow_global_mut<State>(vm_id);
        
        let a2e = &mut state.a2e;
        assert!(!table::contains(a2e, account_addr), error::already_exists(ACCOUNT_ALREADY_EXISTS));
        
        let accounts = &mut state.accounts;
        assert!(!table::contains(accounts, e_addr), error::already_exists(ACCOUNT_ALREADY_EXISTS));

        table::add(a2e, account_addr, e_addr);
        table::add(accounts, e_addr, Account {
            balance: 0,
            state: table::new<u128, u128>(),
        });
    }

    public entry fun read(vm_id: address, addr: address, slot: u128): u128 acquires State {
        let state = borrow_global<State>(vm_id);

        let a2e = &state.a2e;
        assert!(table::contains(a2e, addr), error::already_exists(ACCOUNT_NOT_FOUND));
        let e_addr = table::borrow(a2e, addr);

        let acct = table::borrow(&state.accounts, *e_addr);
        if(table::contains(&acct.state, slot)) {
            *table::borrow(&acct.state, slot)
        } else {
            0
        }
    }

    public entry fun write(vm_id: address, addr: address, slot: u128, val: u128) acquires State {
        let state = borrow_global_mut<State>(vm_id);

        let a2e = &mut state.a2e;
        assert!(table::contains(a2e, addr), error::already_exists(ACCOUNT_NOT_FOUND));
        let e_addr = table::borrow(a2e, addr);
        let acct = table::borrow_mut(&mut state.accounts, *e_addr);
        
        if(table::contains(&acct.state, slot)) {    
            let v = table::borrow_mut(&mut acct.state, slot);
            *v = val;
        } else {
            table::add(&mut acct.state, slot, val);
        }
    }

    // public entry fun deposit(addr: address) {
    //     borrow_global<State>(vm_id, )
    // }

    // public entry fun withdraw(acct: &signer) {

    // }

//:!:>resource
    struct MessageHolder has key {
        message: string::String,
        message_change_events: event::EventHandle<MessageChangeEvent>,
    }
//<:!:resource

    struct MessageChangeEvent has drop, store {
        from_message: string::String,
        to_message: string::String,
    }

    /// There is no message present
    const ENO_MESSAGE: u64 = 0;

    public fun get_message(addr: address): string::String acquires MessageHolder {
        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));
        *&borrow_global<MessageHolder>(addr).message
    }

    public entry fun set_message(account: signer, message: string::String)
    acquires MessageHolder {
        let account_addr = signer::address_of(&account);
        if (!exists<MessageHolder>(account_addr)) {
            move_to(&account, MessageHolder {
                message,
                message_change_events: account::new_event_handle<MessageChangeEvent>(&account),
            })
        } else {
            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);
            let from_message = *&old_message_holder.message;
            event::emit_event(&mut old_message_holder.message_change_events, MessageChangeEvent {
                from_message,
                to_message: copy message,
            });
            old_message_holder.message = message;
        }
    }

    #[test(account = @0x1)]
    public entry fun sender_can_set_message(account: signer) acquires MessageHolder {
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        set_message(account, string::utf8(b"Hello World"));

        assert!(
          get_message(addr) == string::utf8(b"Hello World"),
          ENO_MESSAGE
        );
    }
}