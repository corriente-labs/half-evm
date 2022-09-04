# Getting Started
Install Aptos cli following the instructions described [here](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli)

## Build and Install
```
git clone https://github.com/aptos-labs/aptos-core.git
cd aptos-core/
./scripts/dev_setup.sh
source ~/.cargo/env
git checkout --track origin/devnet
cargo build --package aptos --release
export PATH=$PATH:$HOME/repos/aptos-core/target/release
```
```
aptos --version
```
cli doc: https://aptos.dev/cli-tools/aptos-cli-tool/use-aptos-cli
## Setup account
```
aptos init
```
```
aptos account list --query balance --account 21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786
```
You should see account funded from devnet faucet.
## Build your own Move module (only if you are creating module)
```
aptos move init --name poc-vm
```
In `Move.toml`, 
1. Change git link of dependency.AptosFramework to `https://github.com/aptos-labs/aptos-core.git`.
2. Change rev to the build commit hash obtained by `aptos info` command.

### Compile
```
aptos move compile --package-dir ./ --named-addresses pocvm=default
```

### Test
```
aptos move test --package-dir ./ --named-addresses pocvm=default
```

### Prove
Install dependencies: https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/#step-3-optional-install-the-dependencies-of-move-prover
```
aptos move prove --package-dir ./ --named-addresses pocvm=default
```

### Print Stacktrace
- https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/#step-3-optional-install-the-dependencies-of-move-prover

### Publish
Use default account `21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786`. Replace with yours as needed.
```
aptos move publish --package-dir ./ --named-addresses pocvm=default
```
```
{
  "Result": {
    "transaction_hash": "0x699e09901a98f0c748682bf676a7e4a9a0ac773402de9c091be865bc6936e7ee",
    "gas_used": 188,
    "gas_unit_price": 1,
    "sender": "21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786",
    "sequence_number": 0,
    "success": true,
    "timestamp_us": 1661783526147980,
    "version": 21019094,
    "vm_status": "Executed successfully"
  }
}
```
You should see the transaction detail in explorer https://explorer.devnet.aptos.dev/txn/21019094.

### Call
```
aptos move run --function-id 0x21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786::message::set_message --args string:hi!
```
```
{
  "Result": {
    "transaction_hash": "0xfa934f1222e0d9f9c415405846a0971518636c4f69ec86d8869b5b77035dfcd7",
    "gas_used": 16,
    "gas_unit_price": 1,
    "sender": "21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786",
    "sequence_number": 2,
    "success": true,
    "timestamp_us": 1661784048523919,
    "version": 21055548,
    "vm_status": "Executed successfully"
  }
}
```
You should see you data at `0x21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786::message::MessageHolder` be modified. https://explorer.devnet.aptos.dev/account/0x21b2b52b63d16db70c44995d08023133286340f44324de3c8788f3598848b786