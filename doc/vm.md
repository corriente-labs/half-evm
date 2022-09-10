# Build
```
aptos move compile --package-dir ./ --named-addresses pocvm=vmer
```

# Publish
```
aptos move publish --package-dir ./ --named-addresses pocvm=vmer --profile vmer --max-gas 5000
```
`--max-gas` option to increase gas.

# Call
## init
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::init --type-args signer "vector<u8>" --args address:9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b hex:"dddddd" --profile vmer

aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::init --args hex:dddddd --profile vmer

aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::init --args hex:dddddd --profile default

```

## init2
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::init2 --profile vmer
```

## init3
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::init3 --profile vmer
```

## call
Not Allowed
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call --type-args signer hex --args hex:0011223344
```

## call0
To test hex argument
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call0 --args hex:0011223344
```

## call2
```rs
fun call2(vm_id: address, caller: u128, to: u128, value: u64, calldata: vector<u8>, code: vector<u8>)
```

### test_arith
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call2 --args address:0x50c4155a6b749c6e17753f67898fbb1a8adba66683ccea38e38c872023f5d13d u128:49152 u128:49153 u64:1000 hex:00 hex:600161000201336000526000510160005260106000f3
```
https://explorer.devnet.aptos.dev/txn/64170130

### test_calldata
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call2 --args address:0x50c4155a6b749c6e17753f67898fbb1a8adba66683ccea38e38c872023f5d13d u128:49152 u128:49153 u64:1000 hex:00000000000000000000000000000001 hex:600035601060006000376000510161000101336000526000516000556000540160015560015460015260106001f3
```
https://explorer.devnet.aptos.dev/txn/64184736

### test_sstore_many
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call2 --args address:0x50c4155a6b749c6e17753f67898fbb1a8adba66683ccea38e38c872023f5d13d u128:49152 u128:49153 u64:1000 hex:00000000000000000000000000000001 hex:6f000000000000000000000000000000016f00000000000000000000000000000000556f000000000000000000000000000000016f00000000000000000000000000000001556f000000000000000000000000000000016f00000000000000000000000000000002556f000000000000000000000000000000016f00000000000000000000000000000003556f000000000000000000000000000000016f00000000000000000000000000000004556f000000000000000000000000000000016f00000000000000000000000000000005556f000000000000000000000000000000016f00000000000000000000000000000006556f000000000000000000000000000000016f00000000000000000000000000000007556f000000000000000000000000000000016f00000000000000000000000000000008556f000000000000000000000000000000016f00000000000000000000000000000009556f000000000000000000000000000000016f0000000000000000000000000000000a556f000000000000000000000000000000016f0000000000000000000000000000000b556f000000000000000000000000000000016f0000000000000000000000000000000c556f000000000000000000000000000000016f0000000000000000000000000000000d556f000000000000000000000000000000016f0000000000000000000000000000000e556f000000000000000000000000000000016f0000000000000000000000000000000f556f00000000000000000000000000000000546f00000000000000000000000000000001546f00000000000000000000000000000002546f00000000000000000000000000000003546f00000000000000000000000000000004546f00000000000000000000000000000005546f00000000000000000000000000000006546f00000000000000000000000000000007546f00000000000000000000000000000008546f00000000000000000000000000000009546f0000000000000000000000000000000a546f0000000000000000000000000000000b546f0000000000000000000000000000000c546f0000000000000000000000000000000d546f0000000000000000000000000000000e546f0000000000000000000000000000000f5401010101010101010101010101010160005260106000f3
```

# Pseudo code

```rs

// mint balance needed to call evm.
// minter is FeePayer. mintee is caller account.
// caller_initial_balance: gasPrice * gasLimit
// create_fee is a fee paid to call this function.
// commitment is recorded to evm so later call to `call` function can be authorized.
pub func mint_caller(authorizer: signer, caller: address, caller_initial_balance: u64, create_fee: u64, evm_user_address: u256, commitment: vector<u8>) {
    asserts(address_of(authorizer) == FEE_PAYER_ADDRESS, "only fee payer can call this function");
    
    // evm_user_address must hold enough balance to pay create_fee
    asserts(evm::balance(evm_user_address) >= create_fee, "evm user address can't pay create_fee");

    asserts(evm::balance(evm_user_address) >= create_fee + caller_initial_balance, "evm user address can't pay entire fee");

    // register commitment to the transaction
    evm::commit(commitment);

    // return create_fee to FEE_PAYER_EVM_ADDRESS
    evm::withdraw(evm_user_address, FEE_PAYER_EVM_ADDRESS, create_fee);

    // send calling fee to caller account
    evm::withdraw(evm_user_address, caller, caller_initial_balance);
}

// execute evm transaction
// this function is called by caller account, which is created in `mint_caller` function.
pub func call(evm_user_address: u256, to: u256, val: u64, calldata: vector<u8>, nonce: u128, signature: vector<u8>) {
    let current_nonce = evm::get_nonce(evm_user_address);
    asserts(current_nonce == nonce, "nonce not valid");

    let current_balance = evm::get_balance(evm_user_address);
    asserts(current_balance >= val, "insufficient balance"); // balance check could be done in `evm::transfer` function

    let transfer_success = evm::transfer(evm_user_address, to, val);
    asserts(transfer_success, "transfer failed");
    
    let hash = evm::keccak256(evm_user_address: u256, to: u256, val: u64, calldata: vector<u8>, nonce: u128);
    asserts(evm::validate_sig(hash, signature), "signature not validated");

    asserts(evm::exists_unrealized_commitment(hash), "commitment not exist or already realized.")

    // start interpretation
    let call_success = evm::call(evm_user_address, to, val, calldata);
    asserts(call_success, "call failed");
}
```