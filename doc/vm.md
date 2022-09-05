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