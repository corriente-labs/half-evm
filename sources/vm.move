module pocvm::vm {
    use std::error;
    use std::signer;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_std::table::{Self, Table};

    const STATE_ALREADY_EXISTS: u64 = 0;
    const ACCOUNT_ALREADY_EXISTS: u64 = 1;

    const ACCOUNT_NOT_FOUND: u64 = 2;
    const INSUFFICIENT_BALANCE: u64 = 3;

    const VM_CALL_DEPTH_OVERFLOW: u64 = 1000;

    struct Message has copy, drop {
        origin: u128,
        caller: u128,
        to: u128,
        value: u64,
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
        code: vector<u8>,
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
            code: vector::empty(),
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

    #[test_only]
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

    fun exec(vm_id: address, message: &Message): vector<u8> acquires State {
        let state = borrow_global_mut<State>(vm_id);

        let caller_acct = table::borrow_mut(&mut state.accounts, message.caller);
        caller_acct.balance = caller_acct.balance - message.value;

        let callee_acct = table::borrow_mut(&mut state.accounts, message.to);

        let stack = vector::empty<u128>();
        let memory = vector::empty<u8>();
        let ret_data = vector::empty<u8>();
        let depth = 0;

        run(message.caller, callee_acct, &message.data, &mut stack, &mut memory, &mut ret_data, &mut depth);

        return vector::empty()
    }

    fun run(
        caller_addr: u128,
        callee: &mut Account,
        calldata: &vector<u8>,
        stack: &mut vector<u128>,
        memory: &mut vector<u8>,
        ret_data: &mut vector<u8>,
        depth: &mut u64)
    {
        let pc: u64 = 0;

        assert!(*depth < 1024, VM_CALL_DEPTH_OVERFLOW);

        while(pc < vector::length<u8>(&callee.code)) {
            let op = *vector::borrow<u8>(&callee.code, pc);
            
            // stop
            if (op == 0x00) {
                break
            };

            // add
            if (op == 0x01) {
                let lhs = vector::pop_back<u128>(stack);
                let rhs = vector::pop_back<u128>(stack);
                let result = lhs + rhs;
                vector::push_back<u128>(stack, result);
                pc = pc + 1;
                continue
            };

            // mul
            if (op == 0x02) {
                let lhs = vector::pop_back<u128>(stack);
                let rhs = vector::pop_back<u128>(stack);
                let result = lhs * rhs;
                vector::push_back<u128>(stack, result);
                pc = pc + 1;
                continue
            };

            // sub
            if (op == 0x03) {
                let lhs = vector::pop_back<u128>(stack);
                let rhs = vector::pop_back<u128>(stack);
                let result = lhs - rhs;
                vector::push_back<u128>(stack, result);
                pc = pc + 1;
                continue
            };

            // div
            if (op == 0x03) {
                let lhs = vector::pop_back<u128>(stack);
                let rhs = vector::pop_back<u128>(stack);
                let result = lhs / rhs;
                vector::push_back<u128>(stack, result);
                pc = pc + 1;
                continue
            };

            // pop
            if (op == 0x50) {
                let _ = vector::pop_back<u128>(stack);
            };
            
            // push-n
            if (op >= 0x60 && op <= 0x6f) {
                let index = pc + 1 + (op as u64) - 0x60;
                let value = 0u128;
                let count = 0;
                while(index > pc) {
                    let byte = *vector::borrow<u8>(&callee.code, index);
                    value = value + ((byte as u128)<<(8*count));
                    index = index - 1;
                    count = count + 1;
                };
                vector::push_back<u128>(stack, value);
                pc = pc + 2 + (op as u64) - 0x60;
                continue
            };

            // caller
            if (op == 0x33) {
                vector::push_back(stack, caller_addr);
                pc = pc + 1;
                continue
            };
            
            // callvalue
            if (op == 0x34) {
                pc = pc + 1;
                continue
            };
            
            // calldataload
            if (op == 0x35) {
                pc = pc + 1;
                continue
            };
            
            // calldatasize
            if (op == 0x36) {
                let size = vector::length(calldata);
                vector::push_back<u128>(stack, (size as u128));
                pc = pc + 1;
                continue
            };
            
            // calldatacopy
            if (op == 0x37) {
                let dest_offset = vector::pop_back<u128>(stack);
                let offset = vector::pop_back<u128>(stack);
                let size = vector::pop_back<u128>(stack);

                let dest_offset = (dest_offset as u64);
                let offset = (offset as u64);
                let size = (size as u64);
                
                // extends memory
                if(vector::length(memory) > dest_offset + size) {
                    let new_chunk_length = vector::length(memory) - (dest_offset + size);
                    let count = 0;
                    while(count < new_chunk_length) {
                        vector::push_back(memory, 0u8);
                        count = count + 1;
                    };
                };

                // copy calldata elements to memory
                let index = 0;
                while(index < vector::length(calldata) - offset && index < size) {
                    let value = *vector::borrow(calldata, offset + index);
                    let dest = vector::borrow_mut(memory, dest_offset + index);
                    *dest = value;
                    index = index + 1;
                };

                pc = pc + 1;
            };

            // returndatasize
            if (op == 0x3d) {
                let size = vector::length(ret_data);
                vector::push_back(stack, (size as u128));
                pc = pc + 1;
                continue
            };
            
            // mload
            if (op == 0x51) {
                pc = pc + 1;
                continue
            };

            // mstore
            if (op == 0x52) {
                pc = pc + 1;
                continue
            };

            // sload
            if (op == 0x54) {
                let slot = vector::pop_back<u128>(stack);
                let val = sload(callee, slot);
                vector::push_back<u128>(stack, val);
                pc = pc + 1;
                continue
            };

            // sstore
            if (op == 0x55) {
                let slot = vector::pop_back<u128>(stack);
                let val = vector::pop_back<u128>(stack);
                sstore(callee, slot, val);
                pc = pc + 1;
                continue
            };

            // jump
            if (op == 0x56) {
                let dest = vector::pop_back<u128>(stack);
                pc = (dest as u64);
                continue
            };

            // jumpi
            if (op == 0x57) {
                pc = pc + 1;
                continue
            };

            // msize
            if (op == 0x59) {
                let size = vector::length(memory);
                vector::push_back<u128>(stack, (size as u128));
                pc = pc + 1;
                continue
            };

            // jumpdest
            if (op == 0x5b) {
                pc = pc + 1;
                continue
            };

            // balance
            if (op == 0x31) {
                pc = pc + 1;
                continue
            };

            // call
            if (op == 0xf1) {
                pc = pc + 1;
                continue
            };

            // return
            if (op == 0xf3) {
                let ret = vector::empty<u8>();
                let top = vector::pop_back<u128>(stack);
                let count = 0;
                while(count < 16) {
                    let byte = (top>>(8 * count)) & 0xff;
                    vector::push_back<u8>(&mut ret, (byte as u8));
                    count = count + 1;
                };
                vector::reverse(&mut ret);
                pc = pc + 1;
            };
        };
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