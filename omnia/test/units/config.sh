#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/util.sh"
. "$lib_path/config.sh"

. "$root_path/lib/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

_validConfig="$(jq -c . "$test_path/configs/oracle-relay-test.json")"

# Setting up clean vars
ETH_GAS_SOURCE=""
ETH_MAXPRICE_MULTIPLIER=""
ETH_TIP_MULTIPLIER=""
ETH_GAS_PRIORITY=""

# Testing default values
_json=$(jq -c '.ethereum' <<< "$_validConfig")
assert "importGasPrice should correctly parse values" run importGasPrice $_json

assert "ETH_GAS_SOURCE should have value: ethgasstation" match "^node" <<<$ETH_GAS_SOURCE
assert "ETH_MAXPRICE_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "ETH_TIP_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "ETH_GAS_PRIORITY should have value: slow" match "^fast" <<<$ETH_GAS_PRIORITY

# Testing changed values
_json="{\"gasPrice\":{\"source\":\"ethgasstation\",\"maxPriceMultiplier\":0.5,\"tipMultiplier\":1.0,\"priority\":\"slow\"}}"
assert "importGasPrice should correctly parse new values" run importGasPrice $_json

assert "ETH_GAS_SOURCE should have value: ethgasstation" match "^ethgasstation$" <<<$ETH_GAS_SOURCE
assert "ETH_MAXPRICE_MULTIPLIER should have value: 0.5" match "^0.5$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "ETH_TIP_MULTIPLIER should have value: 1" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "ETH_GAS_PRIORITY should have value: slow" match "^slow$" <<<$ETH_GAS_PRIORITY

# Testing importNetwork() & Infura keys

# Mocking ETH-RPC request
getLatestBlock () {
  printf "1"
}
export -f getLatestBlock

_network_json='{"network":"http://geth.local:8545","infuraKey":"wrong-key"}'

errors=()
assert "importNetwork: infuraKey should fail if incorrect key configured" fail importNetwork $_network_json

errors=()
assert "importNetwork: infuraKey should give valid error message" match "Error - Invalid Infura Key" < <(capture importNetwork $_network_json)

# NOTE: We have to reset `errors` after failed run
errors=()
_network_json='{"network":"http://geth.local:8545"}'
assert "importNetwork: missing infuraKey should pass validation" run importNetwork $_network_json

_network_json='{"network":"http://geth.local:8545","infuraKey":""}'
assert "importNetwork: empty infuraKey should pass validation" run importNetwork $_network_json

INFURA_KEY=""
_network_json='{"network":"http://geth.local:8545","infuraKey":"305ac4ca797b6fa19d5e985b8269f6c5"}'\

assert "importNetwork: valid infuraKey should pass validation" run importNetwork $_network_json
assert "importNetwork: valid infuraKey should be set as ENV var" match "^305ac4ca797b6fa19d5e985b8269f6c5$" <<<$INFURA_KEY

assert "importNetwork: custom network should be set correctly" run importNetwork $_network_json
assert "importNetwork: custom network value should be set to ENV var ETH_RPC_URL" match "^http://geth.local:8545$" <<<$ETH_RPC_URL

unset ETH_RPC_URL
assert "importNetwork: ethlive netork shouldn't crash" run importNetwork '{"network":"ethlive"}'
assert "importNetwork: ethlive network should expand to full url" match "^https://mainnet.infura.io" <<<$ETH_RPC_URL

unset ETH_RPC_URL
assert "importNetwork: mainnet netork shouldn't crash" run importNetwork '{"network":"mainnet"}'
assert "importNetwork: mainnet network should expand to full url" match "^https://mainnet.infura.io" <<<$ETH_RPC_URL

unset ETH_RPC_URL
assert "importNetwork: ropsten netork shouldn't crash" run importNetwork '{"network":"ropsten"}'
assert "importNetwork: ropsten network should expand to full url" match "^https://ropsten.infura.io" <<<$ETH_RPC_URL

unset ETH_RPC_URL
assert "importNetwork: kovan netork shouldn't crash" run importNetwork '{"network":"kovan"}'
assert "importNetwork: kovan network should expand to full url" match "^https://kovan.infura.io" <<<$ETH_RPC_URL

unset ETH_RPC_URL
assert "importNetwork: rinkeby netork shouldn't crash" run importNetwork '{"network":"rinkeby"}'
assert "importNetwork: rinkeby network should expand to full url" match "^https://rinkeby.infura.io" <<<$ETH_RPC_URL

unset ETH_RPC_URL
assert "importNetwork: goerli netork shouldn't crash" run importNetwork '{"network":"goerli"}'
assert "importNetwork: goerli network should expand to full url" match "^https://goerli.infura.io" <<<$ETH_RPC_URL

getLatestBlock () {
  printf "some error message"
}
export -f getLatestBlock
assert "importNetwork: invalid block number should fail execution" fail importNetwork '{"network":"goerli"}'

getLatestBlock () {
  printf ""
}
export -f getLatestBlock
assert "importNetwork: empty block number should fail execution" fail importNetwork '{"network":"goerli"}'

# importMode tests
errors=()
assert "importMode: fails on invalid mode" fail importMode '{"mode":"blahblah"}'

errors=()
assert "importMode: fails on feed" fail importMode '{"mode":"feed"}'
assert "importMode: works correctly on relay" run importMode '{"mode":"relay"}'

export OMNIA_MODE=""
assert "importMode: works correctly" run importMode '{"mode":"relay"}'
assert "importMode: actualy sets ENV var in upper case" match "^RELAY$" <<<$OMNIA_MODE

# importGasPrice function
export ETH_GAS_SOURCE=""
export ETH_MAXPRICE_MULTIPLIER=""
export ETH_TIP_MULTIPLIER=""
export ETH_GAS_PRIORITY=""
# executing importGasPrice
importGasPrice '{}'
assert "importGasPrice: set default source to 'node'" match "^node$" <<<$ETH_GAS_SOURCE
assert "importGasPrice: set default maxPriceMultiplier to '1'" match "^1$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "importGasPrice: set default tipMultiplier to '1'" match "^1$" <<<$ETH_TIP_MULTIPLIER
assert "importGasPrice: set default priority to 'fast'" match "^fast$" <<<$ETH_GAS_PRIORITY

assert "importGasPrice: fails on invalid maxPriceMultiplier" match "^Error - Ethereum Gas max price multiplier is invalid" < <(capture importGasPrice '{"gasPrice":{"maxPriceMultiplier":"asdf"}}')
assert "importGasPrice: fails on invalid tipMultiplier" match "^Error - Ethereum Gas price tip multiplier is invalid" < <(capture importGasPrice '{"gasPrice":{"maxPriceMultiplier":1,"tipMultiplier":"asdf"}}')
assert "importGasPrice: fails on invalid priority" match "^Error - Ethereum Gas price priority is invalid" < <(capture importGasPrice '{"gasPrice":{"maxPriceMultiplier":1,"tipMultiplier":1,"priority":"wrong"}}')

export ETH_GAS_SOURCE=""
export ETH_MAXPRICE_MULTIPLIER=""
export ETH_TIP_MULTIPLIER=""
export ETH_GAS_PRIORITY=""

_json='{"gasPrice":{"source":"other","maxPriceMultiplier":2,"tipMultiplier":2,"priority":"fastest"}}'
assert "importGasPrice: correctly works" run importGasPrice "$_json"
assert "importGasPrice: set given source to 'other'" match "^other$" <<<$ETH_GAS_SOURCE
assert "importGasPrice: set given maxPriceMultiplier to '2'" match "^2$" <<<$ETH_MAXPRICE_MULTIPLIER
assert "importGasPrice: set given tipMultiplier to '2'" match "^2$" <<<$ETH_TIP_MULTIPLIER
assert "importGasPrice: set given priority to 'fastest'" match "^fastest$" <<<$ETH_GAS_PRIORITY

# importFeeds function
assert "importFeeds: fails on invalid address" fail importFeeds '{"address":"@uqOcvBdpBXWNCm5WhjALbtyR8szWpihH/CVyNdycncQ=.ed25519","0x75FBD0aaCe74Fb05ef0F6C0AC63d26071Eb750c9":"@wrrCKd56pV5CNSVh+fkVh6iaRUG6VA5I5VDEo8XOn5E=.ed25519","0x0c4FC7D66b7b6c684488c1F218caA18D4082da18":"@4ltZDRGFi4eHGGlXmLC8olcEs8XNZCXfvx+3V3S2HgY=.ed25519","0xC50DF8b5dcb701aBc0D6d1C7C99E6602171Abbc4":"@gt/2QK1AdSCLX3zRJQV6wRRsoxgohChCpjmNOOLUAA4=.ed25519"}'
assert "importFeeds: works with correct address" run importFeeds '{"0xBb94f7C5f14fd29EE744b5A54f05f29aE488Fe77":"@uqOcvBdpBXWNCm5WhjALbtyR8szWpihH/CVyNdycncQ=.ed25519"}'
assert "importFeeds: puled address" match "^0xBb94f7C5f14fd29EE744b5A54f05f29aE488Fe77$" <<<${feeds[0]}

# importServicesEnv function
assert "importServicesEnv: fails on non object scuttlebotIdMap" fail importServicesEnv '{"scuttlebotIdMap":[]}'

errors=()
assert "importServicesEnv: runs without errors if no address provided" run importServicesEnv '{"scuttlebotIdMap":{}}'

export SSB_ID_MAP=""
importServicesEnv '{}'
assert "importServicesEnv: set default ssb details if non provided" match "{}" <<<$SSB_ID_MAP

export SSB_ID_MAP=""
importServicesEnv '{"scuttlebotIdMap":{"0xBb94f7C5f14fd29EE744b5A54f05f29aE488Fe77":"@wrrCKd56pV5CNSVh+fkVh6iaRUG6VA5I5VDEo8XOn5E=.ed25519"}}'
assert "importServicesEnv: set provided address to SSB_ID_MAP" match "0xBb94f7C5f14fd29EE744b5A54f05f29aE488Fe77" <<<$SSB_ID_MAP
