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

## simulate
https://fullnode.devnet.aptoslabs.com/v1/spec#/operations/simulate_transaction
#### example
```
curl --request POST \
  --url https://fullnode.devnet.aptoslabs.com/v1/transactions/simulate \
  --header 'Content-Type: application/json' \
  --data '{
  "sender": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
  "sequence_number": "0",
  "max_gas_amount": "2000",
  "gas_unit_price": "100",
  "expiration_timestamp_secs": "32425224034",
  "payload": {
    "type": "entry_function_payload",
    "function": "0x1::coin::transfer",
    "type_arguments": [
      "0x1::aptos_coin::AptosCoin"
    ],
    "arguments": [
      "0xf3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b",
      "1"
    ]
  },
  "signature": {
    "type": "ed25519_signature",
    "public_key": "0xb0d9526e61b50ecf621de31a6a69fefc2d6383abb33372c763aeebc53dc4aeaa",
    "signature": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  }
}'
```
#### response
```json
[
  {
    "version": "11451293",
    "hash": "0x82d5ea7a95ca302b548234b48502b6a1ce8a0ba5cceff300aa28808fba4bed06",
    "state_change_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "event_root_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "state_checkpoint_hash": null,
    "gas_used": "253",
    "success": true,
    "vm_status": "Executed successfully",
    "accumulator_root_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "changes": [
      {
        "address": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
        "state_key_hash": "0x81c9532c052f85cade80c11c9b49d8bb37021900072248cbb9113f7cda21bac9",
        "data": {
          "type": "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>",
          "data": {
            "coin": {
              "value": "174699"
            },
            "deposit_events": {
              "counter": "1",
              "guid": {
                "id": {
                  "addr": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
                  "creation_num": "2"
                }
              }
            },
            "frozen": false,
            "withdraw_events": {
              "counter": "1",
              "guid": {
                "id": {
                  "addr": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
                  "creation_num": "3"
                }
              }
            }
          }
        },
        "type": "write_resource"
      },
      {
        "address": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
        "state_key_hash": "0x78ebcc421025f27e5a9acc3e699e59d7587801ba51094295f8ac3de17c1ebb1c",
        "data": {
          "type": "0x1::account::Account",
          "data": {
            "authentication_key": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
            "coin_register_events": {
              "counter": "1",
              "guid": {
                "id": {
                  "addr": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
                  "creation_num": "0"
                }
              }
            },
            "guid_creation_num": "4",
            "key_rotation_events": {
              "counter": "0",
              "guid": {
                "id": {
                  "addr": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
                  "creation_num": "1"
                }
              }
            },
            "rotation_capability_offer": {
              "for": {
                "vec": []
              }
            },
            "sequence_number": "1",
            "signer_capability_offer": {
              "for": {
                "vec": []
              }
            }
          }
        },
        "type": "write_resource"
      },
      {
        "address": "0xf3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b",
        "state_key_hash": "0xb41a94d99cf51967d72ed69282ddba1165306d2df702eacd488654f019e6606a",
        "data": {
          "type": "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>",
          "data": {
            "coin": {
              "value": "1"
            },
            "deposit_events": {
              "counter": "1",
              "guid": {
                "id": {
                  "addr": "0xf3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b",
                  "creation_num": "2"
                }
              }
            },
            "frozen": false,
            "withdraw_events": {
              "counter": "0",
              "guid": {
                "id": {
                  "addr": "0xf3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b",
                  "creation_num": "3"
                }
              }
            }
          }
        },
        "type": "write_resource"
      },
      {
        "state_key_hash": "0x6e4b28d40f98a106a65163530924c0dcb40c1349d3aa915d108b4d6cfc1ddb19",
        "handle": "0x1b854694ae746cdbd8d44186ca4929b2b337df21d1c74633be19b2710552fdca",
        "key": "0x0619dc29a0aac8fa146714058e8dd6d2d0f3bdf5f6331907bf91f3acd81e6935",
        "value": "0xc9dd025b119909000100000000000000",
        "data": null,
        "type": "write_table_item"
      }
    ],
    "sender": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
    "sequence_number": "0",
    "max_gas_amount": "2000",
    "gas_unit_price": "100",
    "expiration_timestamp_secs": "32425224034",
    "payload": {
      "function": "0x1::coin::transfer",
      "type_arguments": [
        "0x1::aptos_coin::AptosCoin"
      ],
      "arguments": [
        "0xf3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b",
        "1"
      ],
      "type": "entry_function_payload"
    },
    "signature": {
      "public_key": "0xb0d9526e61b50ecf621de31a6a69fefc2d6383abb33372c763aeebc53dc4aeaa",
      "signature": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "type": "ed25519_signature"
    },
    "events": [
      {
        "key": "0x03000000000000006e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe",
        "guid": {
          "creation_number": "3",
          "account_address": "0x6e1caaaaa801faaa802e98f0b7e4ee1c6f97d81cd3514ffa2ba65f8e807ff5fe"
        },
        "sequence_number": "0",
        "type": "0x1::coin::WithdrawEvent",
        "data": {
          "amount": "1"
        }
      },
      {
        "key": "0x0200000000000000f3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b",
        "guid": {
          "creation_number": "2",
          "account_address": "0xf3ee9f543996f594c3632919f8604fce8ebf7919dc2df0bed35d257a6de0f61b"
        },
        "sequence_number": "0",
        "type": "0x1::coin::DepositEvent",
        "data": {
          "amount": "1"
        }
      }
    ],
    "timestamp": "1664036092275639"
  }
]
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