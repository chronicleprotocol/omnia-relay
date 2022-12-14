#!/bin/bash
test_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
root_path=$(cd "$test_path/../.."; pwd)
lib_path="$root_path/lib"

. "$lib_path/log.sh"
. "$lib_path/util.sh"
. "$lib_path/config.sh"
. "$lib_path/gasprice.sh"
. "$lib_path/relay.sh"

. "$root_path/tap.sh" 2>/dev/null || . "$root_path/test/tap.sh"

# Setting up relay configuration
OMNIA_MODE="RELAY"

_json=$(jq -e . "$test_path/configs/oracle-relay-test.conf")
importAssetPairsEnv "$_json"

assert "assetPairs assigned" match "3" < <(capture printf ${#assetPairs[@]})

_pricePulled="false"

resetTestState() {
  _pricePulled="false"
}
export -f resetTestState

extractPrices() { printf "" ; }
export -f extractPrices

getMedian() { printf "" ; }
export -f getMedian

# Mocking isPriceValid to prevent publishing messages
isPriceValid() { printf "false" ; }
export -f isPriceValid

isQuorum() { printf "false" ; }
export -f isQuorum

# Testing for empty quorum
pullOracleQuorum() { printf "" ; }
export -f pullOracleQuorum

# Expect to filter one of the feeds below when we pull messages from transport
test_filterFeedOnPull() {
    resetTestState
    local feeds=(
        0xDEaDBeefdeadBeEfdEadBEEFDeADBEEF00000001
        0xDEaDBeefdeadBeEfdEadBEEFDeADBEEF00000002
        0xDEaDBeefdeadBeEfdEadBEEFDeADBEEF00000003
        0xDEaDBeefdeadBeEfdEadBEEFDeADBEEF00000004
        0xDEaDBeefdeadBeEfdEadBEEFDeADBEEF00000005
    )
    isAssetPair () {
        echo 'true'
    }
    isMsgExpired () {
        echo 'false'
    }
    isMsgNew () {
        echo 'true'
    }
    isFeedLifted () {
        if [ "$2" = "0xDEaDBeefdeadBeEfdEadBEEFDeADBEEF00000003" ]; then
            echo '0'
        else
            echo '1'
        fi
    }
    pullOracleTime () {
        echo '1'
    }
    transportPull () {
        echo '1'
    }
    log () {
        >&2 echo "$@"
    }
    export -f isAssetPair
    export -f isMsgExpired
    export -f isMsgNew
    export -f isFeedLifted
    export -f pullOracleTime
    export -f transportPull
    export -f log

    local entries=()
    assert "pullLatestPricesOfAssetPair runs without failure" run pullLatestPricesOfAssetPair "BTC/USD" "5"
    assert "pullLatestPricesOfAssetPair entries are filtered" match "1 1 1 1" <<<"${entries[@]}"
} && test_filterFeedOnPull
# ^ run before mock of pullLatestPricesOfAssetPair() below

pullLatestPricesOfAssetPair() { _pricePulled="true" ; }
export -f pullLatestPricesOfAssetPair

# Reset test vars before testing
resetTestState 
assert "updateOracle runs without failure" run updateOracle
assert "updateOracle with empty quorum should not call pullLatestPricesOfAssetPair" match "false" <<<$_pricePulled

# testing for 0 quorum
pullOracleQuorum() { printf "0" ; }
export -f pullOracleQuorum

# Reset test vars before testing
resetTestState
assert "updateOracle runs without failure" run updateOracle
assert "updateOracle with quorum 0 should not call pullLatestPricesOfAssetPair" match "false" <<<$_pricePulled

pullOracleQuorum() { printf "12" ; }
export -f pullOracleQuorum

# Reset test vars before testing
resetTestState
assert "updateOracle runs without failure" run updateOracle
assert "updateOracle call pullLatestPricesOfAssetPair with correct quorum" match "true" <<<$_pricePulled

# testing with valid quorum
isQuorum() { printf "true" ; }
# export -f isQuorum

# Reset test vars before testing
resetTestState
assert "updateOracle runs without failure" run updateOracle
assert "updateOracle call pullLatestPricesOfAssetPair with correct quorum" match "true" <<<$_pricePulled

