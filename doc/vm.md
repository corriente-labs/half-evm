# Publish
```
aptos move publish --package-dir ./ --named-addresses pocvm=vmer --profile vmer --max-gas 5000
```
`--max-gas` option to increase gas.

# Call
## init
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::init --args signer:0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b hex:112233ff
```
## call
TODO
```
aptos move run --function-id 0x9d1b0093292f53747d0592a4fb67f75ac71c148b2659e42c574fd82262f0702b::gateway::call --args address:
```