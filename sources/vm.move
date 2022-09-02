module pocvm::vm {
    use std::error;
    use std::signer;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_std::table::{Self, Table};
    use aptos_std::event;

    const WORDSIZE_BYTE: u8 = 16; // 128 bit

    const STATE_ALREADY_EXISTS: u64 = 0;
    const ACCOUNT_ALREADY_EXISTS: u64 = 1;

    const ACCOUNT_NOT_FOUND: u64 = 2;
    const INSUFFICIENT_BALANCE: u64 = 3;

    const VM_CALL_DEPTH_OVERFLOW: u64 = 1000;
    const VM_INSUFFICIENT_BALANCE: u64 = 1001;

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
        events: event::EventHandle<EvmEvent>,
    }

    struct Account has store {
        balance: u64,
        state: Table<u128, u128>,
        code: vector<u8>,
        nonce: u128,
    }

    struct EvmEvent has drop, store {
        data: vector<u8>,
        topics: vector<u128>,
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
            events: account::new_event_handle<EvmEvent>(&resource_signer),
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
        let called_code = caller_acct.code;

        // let callee_acct = table::borrow(&state.accounts, message.to);

        let stack = vector::empty<u128>();
        let memory = vector::empty<u8>();
        let ret_data = vector::empty<u8>(); // TODO: implement correctly
        let depth = 0;

        return run(state,
            message.caller, message.to,
            &called_code,
            &message.data, &mut stack, &mut memory, &mut ret_data,
            &mut depth
        )
    }

    fun run(
        state: &mut State,
        caller_addr: u128,
        callee_addr: u128,
        code: &vector<u8>,
        calldata: &vector<u8>,
        stack: &mut vector<u128>,
        memory: &mut vector<u8>,
        ret_data: &mut vector<u8>,
        depth: &mut u64): vector<u8>
    {
        let pc: u64 = 0;

        assert!(*depth < 1024, VM_CALL_DEPTH_OVERFLOW);

        while(pc < vector::length<u8>(code)) {
            let op = *vector::borrow<u8>(code, pc);
            
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
                    let byte = *vector::borrow<u8>(code, index);
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
                let offset = vector::pop_back<u128>(stack);
                let val = mload(memory, (offset as u64));
                vector::push_back<u128>(stack, val);
                pc = pc + 1;
                continue
            };

            // mstore
            if (op == 0x52) {
                let offset = vector::pop_back<u128>(stack);
                let val = vector::pop_back<u128>(stack);
                mstore(memory, (offset as u64), val);
                pc = pc + 1;
                continue
            };

            // sload
            if (op == 0x54) {
                let slot = vector::pop_back<u128>(stack);
                let callee = table::borrow(&state.accounts, callee_addr);
                let val = sload(callee, slot);
                vector::push_back<u128>(stack, val);
                pc = pc + 1;
                continue
            };

            // sstore
            if (op == 0x55) {
                let slot = vector::pop_back<u128>(stack);
                let val = vector::pop_back<u128>(stack);
                let callee = table::borrow_mut(&mut state.accounts, callee_addr);
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

            // log0
            if (op == 0xa0) {
                let offset = vector::pop_back(stack);
                let size = vector::pop_back(stack);
                let data = mem_slice(memory, (offset as u64), (size as u64));

                event::emit_event(&mut state.events, EvmEvent{
                    data: data,
                    topics: vector::empty<u128>(),
                });

                pc = pc + 1;
                continue
            };

            // log1
            if (op == 0xa0) {
                pc = pc + 1;
                continue
            };

            // call
            if (op == 0xf1) {
                let _gas = vector::pop_back<u128>(stack); // ignored
                let to = vector::pop_back<u128>(stack);
                let value = (vector::pop_back<u128>(stack) as u64);
                let args_offset = vector::pop_back<u128>(stack);
                let args_size = vector::pop_back<u128>(stack);
                let ret_offset = vector::pop_back<u128>(stack);
                let ret_size = vector::pop_back<u128>(stack);

                let next_caller = table::borrow_mut(&mut state.accounts, callee_addr);
                assert!(next_caller.balance >= value, VM_INSUFFICIENT_BALANCE);
                next_caller.balance = next_caller.balance - value;

                let next_callee = table::borrow(& state.accounts, to);
                let called_code = next_callee.code;

                let next_calldata = mem_slice(memory, (args_offset as u64), (args_size as u64));
                let next_stack = vector::empty<u128>();
                let next_memory = vector::empty<u8>();
                let next_ret_data = vector::empty<u8>(); // TODO: implement correctly

                *depth = *depth + 1;    // increment depth

                let ret = run(state,
                    callee_addr, to,
                    &called_code,
                    &next_calldata, &mut next_stack, &mut next_memory, &mut next_ret_data,
                    depth
                );

                let ret_truncated = mem_slice(&mut ret, 0, (ret_size as u64));
                mem_mut(memory, (ret_offset as u64), &ret_truncated);

                pc = pc + 1;
                continue
            };

            // return
            if (op == 0xf3) {
                let offset = (vector::pop_back<u128>(stack) as u64);
                let size = (vector::pop_back<u128>(stack) as u64);
                return mem_slice(memory, offset, size)
            };
        };

        return vector::empty()
    }

    fun mload(memory: &mut vector<u8>, offset: u64): u128 {
        let spillover = offset + (WORDSIZE_BYTE as u64) - vector::length(memory);
        while(spillover > 0) {
            vector::push_back<u8>(memory, 0);
            spillover = spillover - 1;
        };

        let sum: u128 = 0;
        let index: u8 = 0;
        while(index < WORDSIZE_BYTE) {
            let byte = (*vector::borrow(memory, offset + (index as u64)) as u128) << (128 - index*8);
            sum = sum + byte;
            index = index + 1;
        };
        return sum
    }
    fun mstore(memory: &mut vector<u8>, offset: u64, val: u128) {
        let spillover = offset + (WORDSIZE_BYTE as u64) - vector::length(memory);
        while(spillover > 0) {
            vector::push_back<u8>(memory, 0);
            spillover = spillover - 1;
        };

        let index: u8 = 0;
        while(index < WORDSIZE_BYTE) {
            let src = (((val >> index*8) & 0xff) as u8);
            let dst = vector::borrow_mut(memory, offset + ((WORDSIZE_BYTE - 1 - index) as u64));
            *dst = src;
            index = index + 1;
        };
    }
    fun mem_slice(memory: &mut vector<u8>, offset: u64, size: u64): vector<u8> {
        let spillover = offset + size - vector::length(memory);
        while(spillover > 0) {
            vector::push_back<u8>(memory, 0);
            spillover = spillover - 1;
        };

        let index: u64 = 0;
        let ret = vector::empty<u8>();
        while(index < size) {
            let src = vector::borrow(memory, offset + index);
            vector::push_back(&mut ret, *src);
            index = index + 1;
        };
        ret
    }
    fun mem_mut(dst: &mut vector<u8>, dst_offset: u64, src: &vector<u8>) {
        let index = 0;
        while(index < vector::length(src)) {
            let dst_byte = vector::borrow_mut(dst, dst_offset + index);
            *dst_byte = *vector::borrow(src, index);
            index = index + 1;
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