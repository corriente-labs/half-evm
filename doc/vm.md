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
TODO
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call --type-args signer hex --args hex:0011223344
```