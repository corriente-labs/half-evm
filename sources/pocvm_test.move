#[test_only]
module pocvm::vm_tests {
    use std::signer;
    use std::unit_test;
    use std::vector;
    use std::string;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{Self, AptosCoin};

    use pocvm::vm;

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    fun deployer(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(12))
    }

    #[test]
    public entry fun sender_can_set_message() {
        let account = get_account();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        vm::set_message(account,  string::utf8(b"Hello World"));

        assert!(
          vm::get_message(addr) == string::utf8(b"Hello World"),
          0
        );
    }

    #[test]
    public entry fun register_and_read() {
        let account = get_account();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);

        let vm_deployer = deployer();
        let vm_id = vm::init(vm_deployer, x"0011223344ff");

        let e_addr = 1234u128;
        vm::register(vm_id, &account, e_addr);

        assert!(
            vm::read(vm_id, addr, 0) == 0,
            0
        );

        vm::write(vm_id, addr, 0, 10);
        vm::write(vm_id, addr, 1, 11);
        vm::write(vm_id, addr, 2, 12);

        assert!(
            vm::read(vm_id, addr, 0) == 10,
            0
        );

        assert!(
            vm::read(vm_id, addr, 1) == 11,
            0
        );

        assert!(
            vm::read(vm_id, addr, 2) == 12,
            0
        );

        vm::write(vm_id, addr, 2, 22);
        assert!(
            vm::read(vm_id, addr, 2) == 22,
            0
        );
    }

    #[test(user = @0x1111, core_framework = @aptos_framework)]
    public entry fun optin_and_read(user: signer, core_framework: signer) {
        let addr = signer::address_of(&user);

        // mint coin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&core_framework);
        coin::register<AptosCoin>(&user);
        coin::deposit(addr, coin::mint(1000, &mint_cap));

        let vm_deployer = deployer();
        let vm_id = vm::init(vm_deployer, x"0011223344ff");

        let e_addr = 1234u128;
        vm::register(vm_id, &user, e_addr);

        // withdraw from account and deposit to vm
        vm::opt_in(vm_id, &user, 123);

        assert!(
            vm::balance(vm_id, addr) == 123,
            0
        );

        coin::destroy_mint_cap<AptosCoin>(mint_cap);
        coin::destroy_burn_cap<AptosCoin>(burn_cap);
    }
}