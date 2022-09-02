module pocvm::gateway {
    use std::signer;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};

    use pocvm::vm;

    const STATE_ALREADY_EXISTS: u64 = 0;
    const ACCOUNT_ALREADY_EXISTS: u64 = 1;

    const ACCOUNT_NOT_FOUND: u64 = 2;
    const INSUFFICIENT_BALANCE: u64 = 3;

    // init resource account and vm state
    public entry fun init(acct: signer, seed: vector<u8>): address {
        let vm_id = vm::init(&acct, seed);
        vm_id
    }

    public entry fun register(vm_id: address, acct: &signer, e_addr: u128) {
        vm::register(vm_id, acct, e_addr);
    }

    public entry fun read(vm_id: address, addr: address, slot: u128): u128 {
        vm::pub_sload(vm_id, addr, slot)
    }

    #[test_only]
    public entry fun write(vm_id: address, addr: address, slot: u128, val: u128) {
        vm::pub_sstore(vm_id, addr, slot, val);
    }

    public entry fun balance(vm_id: address, addr: address): u64 {
        vm::pub_balance(vm_id, addr)
    }

    public entry fun opt_in(vm_id: address, from: &signer, val: u64) {
        let addr = signer::address_of(from); // address opting-in
        vm::opt_in(vm_id, addr, val);
        coin::transfer<AptosCoin>(from, vm_id, val); // transfer coin
    }

    public entry fun opt_out(vm_id: address, to: &signer, val: u64) {
        let addr = signer::address_of(to); // address opting-out
        let from = vm::opt_out(vm_id, addr, val);
        coin::transfer<AptosCoin>(&from, addr, val); // transfer coin
    }
}