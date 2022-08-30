#[test_only]
module pocvm::message_tests {
    use std::signer;
    use std::unit_test;
    use std::vector;
    use std::string;

    use pocvm::message;

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
        message::set_message(account,  string::utf8(b"Hello World"));

        assert!(
          message::get_message(addr) == string::utf8(b"Hello World"),
          0
        );
    }

    #[test]
    public entry fun register_and_read() {
        let account = get_account();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);

        let vm_deployer = deployer();
        let vm_id = message::init(vm_deployer, x"0011223344ff");

        let e_addr = 1234u128;
        message::register(vm_id, account, e_addr);

        assert!(
            message::read(vm_id, addr, 0) == 0,
            0
        );

        message::write(vm_id, addr, 0, 10);
        message::write(vm_id, addr, 1, 11);
        message::write(vm_id, addr, 2, 12);

        assert!(
            message::read(vm_id, addr, 0) == 10,
            0
        );

        assert!(
            message::read(vm_id, addr, 1) == 11,
            0
        );

        assert!(
            message::read(vm_id, addr, 2) == 12,
            0
        );

        message::write(vm_id, addr, 2, 22);
        assert!(
            message::read(vm_id, addr, 2) == 22,
            0
        );
    }
}