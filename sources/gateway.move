module pocvm::gateway {
    use std::signer;
    use std::vector;
    use std::option;
    use std::hash;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_std::secp256k1;
    // use aptos_std::debug;
    
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

    public entry fun accept_message(e_addr: vector<u8>, digest: vector<u8>, sig: vector<u8>): bool {
        let sig64 = vector::empty<u8>();
        let count = 0;
        while(count < 64) {
            let byte = vector::borrow<u8>(&sig, count);
            vector::push_back(&mut sig64, *byte);
            count = count + 1;
        };
        let signature = secp256k1::ecdsa_signature_from_bytes(sig64);
        let rc = vector::borrow<u8>(&sig, 64);

        let pubkey_ = secp256k1::ecdsa_recover(digest, *rc, &signature);
        let pubkey = secp256k1::ecdsa_raw_public_key_to_bytes(option::borrow(&pubkey_));
        let hashed = hash::sha3_256(pubkey); // use aptos_hash::keccak256() once released.

        // debug::print<vector<u8>>(&pubkey);
        // debug::print<vector<u8>>(&hashed);
        // debug::print<vector<u8>>(&e_addr);

        count = 12;
        while(count < 32) {
            let e = vector::borrow<u8>(&e_addr, count);
            let p = vector::borrow<u8>(&hashed, count);
            if(*e != *p) {
                return false
            };
            count = count + 1;
        };
        return true
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

    // #[test]
    // public entry fun test_accepting_message() {
    //     let e_addr = x"39acf301136ab564b4680ef705da1789f5dba0e8";
    //     let digest = x"3dcd8fba4409eec27d130fe39f5cb6547fd0f07debb2d27e18b90bc285f83c75";
    //     let sig = x"f787a4cdbb38ade27a6617e9e1cb9580976161ba0046eae1bb8b0283f48c7dff279917bf52e23906807ddd712043d188916a81bdf0ccc2f8bf618c37b24afeb100";
    //     let accepted = accept_message(e_addr, digest, sig);
    //     assert!(accepted, 0); 
    // }

    #[test_only]
    public fun fib(n: u128): u128 {
        if (n <= 1) {
            return n
        };
        return fib(n - 1) + fib(n - 2)
    }

    #[test]
    public entry fun test_recursion() {
        let result = fib(16);
        assert!(987 == result, 0);
    }
}