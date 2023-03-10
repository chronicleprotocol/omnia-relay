#initialize environment
initEnv () {
	OMNIA_VERSION="${OMNIA_VERSION:-"0.0.0-unset"}"

	#Load Global configuration
	importEnv || exit 1

	echo ""
	echo ""
	echo "  /\$\$\$\$\$\$                          /\$\$                                "
	echo " /\$\$__  \$\$                        |__/                                    "
	echo "| \$\$  \ \$\$ /\$\$\$\$\$\$/\$\$\$\$  /\$\$\$\$\$\$\$  /\$\$  /\$\$\$\$\$\$  "
	echo "| \$\$  | \$\$| \$\$_  \$\$_  \$\$| \$\$__  \$\$| \$\$ |____  \$\$            "
	echo "| \$\$  | \$\$| \$\$ \ \$\$ \ \$\$| \$\$  \ \$\$| \$\$  /\$\$\$\$\$\$\$       "
	echo "| \$\$  | \$\$| \$\$ | \$\$ | \$\$| \$\$  | \$\$| \$\$ /\$\$__  \$\$          "
	echo "|  \$\$\$\$\$\$/| \$\$ | \$\$ | \$\$| \$\$  | \$\$| \$\$|  \$\$\$\$\$\$\$     "
	echo " \______/ |__/ |__/ |__/|__/  |__/|__/ \_______/                              "
	echo ""
	echo ""
	echo "------------------------------- STARTING OMNIA -------------------------------"
	echo "Bot started $(date)"
	echo "Omnia Relay Version:               v$OMNIA_VERSION"
	echo "Mode:                              $OMNIA_MODE"
	echo "Verbose Mode:                      $OMNIA_VERBOSE"
	echo "Interval:                          $OMNIA_INTERVAL seconds"
	echo ""
	echo "ETHEREUM"
	echo "  ETH_RPC_URL             = $ETH_RPC_URL"
	echo "  ETH_FROM                = $ETH_FROM"
	echo "  ETH_GAS_SOURCE          = $ETH_GAS_SOURCE"
	echo "  ETH_GAS                 = $ETH_GAS"
	echo "  ETH_TX_TYPE             = $ETH_TX_TYPE"
	echo "  ETH_MAXPRICE_MULTIPLIER = $ETH_MAXPRICE_MULTIPLIER"
	[[ $ETH_GAS_SOURCE != "node" ]] && \
	echo "  ETH_GAS_PRIORITY        = $ETH_GAS_PRIORITY"
	echo ""
	echo "  Peers:"
	for feed in "${feeds[@]}"; do
		echo "$feed => $(getId "$feed")"
	done
	echo ""

	echo "ORACLE"
	for assetPair in "${assetPairs[@]}"; do
		printf '   %s\n' "$assetPair"

		[[ "$OMNIA_MODE" == "RELAY" ]] && \
		printf '      Oracle Address:              %s\n' "$(getOracleContract "$assetPair")"

		printf '      Message Expiration:          %s seconds\n' "$(getMsgExpiration "$assetPair")"

		[[ $OMNIA_MODE == "FEED" ]] && \
		printf '      Message Spread:              %s %% \n' "$(getMsgSpread "$assetPair")"

		[[ "$OMNIA_MODE" == "RELAY" ]] && \
		printf '      Oracle Expiration:           %s seconds\n' "$(getOracleExpiration "$assetPair")"

		[[ "$OMNIA_MODE" == "RELAY" ]] && \
		printf '      Oracle Spread:               %s %% \n' "$(getOracleSpread "$assetPair")"
	done
	echo ""
	echo "-------------------------- INITIALIZATION COMPLETE ---------------------------"
	echo ""
}

runRelay () {
    while true; do
		updateOracle
		verbose "Sleeping $OMNIA_INTERVAL seconds.."
		sleep "$OMNIA_INTERVAL"
    done
}