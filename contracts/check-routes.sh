#!/usr/bin/env bash
# Check v6.0.0 route registration status on all 18 chains.
# Usage: ./check-routes.sh [path-to-.env]
#
# Reads gateway addresses from deployments/*.json and calls routes(bytes4)
# on each gateway to determine if the v6 verifiers are registered.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-$SCRIPT_DIR/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo "Usage: $0 [path-to-.env]"
  exit 1
fi

# Source env for RPC URLs
set -a
source "$ENV_FILE"
set +a

# V6 verifier selectors (first 4 bytes of VERIFIER_HASH)
V6_GROTH16_SEL="0x0e78f4db"
V6_PLONK_SEL="0xbb1a6f29"

# Expected v6 verifier addresses (CREATE2-deterministic, same on all chains)
V6_GROTH16="0xEfe0156fe9C4013Dfd3F5D0BFa8dF01B28843e0f"
V6_PLONK="0x8a0fd5e825D14368d90Fe68F31fceAe3E17AFc5C"

# Chain definitions: CHAIN_ID:NAME:RPC_VAR
CHAINS=(
  # Testnets (run these first)
  "11155111:Sepolia:RPC_SEPOLIA"
  "421614:Arbitrum Sepolia:RPC_ARBITRUM_SEPOLIA"
  "84532:Base Sepolia:RPC_BASE_SEPOLIA"
  "11155420:OP Sepolia:RPC_OPTIMISM_SEPOLIA"
  "534351:Scroll Sepolia:RPC_SCROLL_SEPOLIA"
  "560048:Hoodi:RPC_HOODI"
  # Mainnets
  "1:Ethereum:RPC_MAINNET"
  "10:Optimism:RPC_OPTIMISM"
  "42161:Arbitrum:RPC_ARBITRUM"
  "8453:Base:RPC_BASE"
  "534352:Scroll:RPC_SCROLL"
  "56:BSC:RPC_BSC"
  "196:X Layer:RPC_XLAYER"
  "143:Monad:RPC_MONAD"
  "4326:MegaETH:RPC_MEGA"
  "9745:Plasma:RPC_PLASMA"
  "999:HyperEVM:RPC_HYPEREVM"
  "4217:Tempo:RPC_TEMPO"
)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DEPLOY_DIR="$SCRIPT_DIR/deployments"
TIMEOUT=15

# Counters
total=0
registered=0
not_registered=0
errors=0

printf "\n${BOLD}SP1 v6.0.0 Route Registration Status${NC}\n"
printf "Groth16 verifier: ${CYAN}%s${NC}\n" "$V6_GROTH16"
printf "Plonk verifier:   ${CYAN}%s${NC}\n" "$V6_PLONK"
printf "Groth16 selector: ${CYAN}%s${NC}  Plonk selector: ${CYAN}%s${NC}\n\n" "$V6_GROTH16_SEL" "$V6_PLONK_SEL"

printf "${BOLD}%-20s %-10s %-15s %-15s${NC}\n" "CHAIN" "ID" "GROTH16" "PLONK"
printf "%-20s %-10s %-15s %-15s\n" "--------------------" "----------" "---------------" "---------------"

check_route() {
  local gateway="$1"
  local selector="$2"
  local rpc="$3"
  local expected_verifier="$4"

  local result
  result=$(cast call "$gateway" "routes(bytes4)(address,bool)" "$selector" --rpc-url "$rpc" 2>&1) || {
    echo "ERROR"
    return
  }

  # cast returns two lines: address and bool
  local addr
  local frozen
  addr=$(echo "$result" | head -1 | tr -d '[:space:]')
  frozen=$(echo "$result" | tail -1 | tr -d '[:space:]')

  # Zero address means not registered
  if [[ "$addr" == "0x0000000000000000000000000000000000000000" ]]; then
    echo "NOT_REGISTERED"
    return
  fi

  # Check if correct verifier is registered
  local addr_lower
  local expected_lower
  addr_lower=$(echo "$addr" | tr '[:upper:]' '[:lower:]')
  expected_lower=$(echo "$expected_verifier" | tr '[:upper:]' '[:lower:]')

  if [[ "$addr_lower" == "$expected_lower" ]]; then
    if [[ "$frozen" == "true" ]]; then
      echo "FROZEN"
    else
      echo "REGISTERED"
    fi
  else
    echo "WRONG:${addr}"
  fi
}

for chain_def in "${CHAINS[@]}"; do
  IFS=':' read -r chain_id chain_name rpc_var <<< "$chain_def"

  rpc_url="${!rpc_var:-}"
  if [[ -z "$rpc_url" ]]; then
    printf "${YELLOW}%-20s %-10s %-15s %-15s${NC}\n" "$chain_name" "$chain_id" "NO RPC" "NO RPC"
    errors=$((errors + 2))
    total=$((total + 2))
    continue
  fi

  deploy_file="$DEPLOY_DIR/${chain_id}.json"
  if [[ ! -f "$deploy_file" ]]; then
    printf "${YELLOW}%-20s %-10s %-15s %-15s${NC}\n" "$chain_name" "$chain_id" "NO DEPLOY" "NO DEPLOY"
    errors=$((errors + 2))
    total=$((total + 2))
    continue
  fi

  # Read gateway addresses from deployment JSON
  gw_groth16=$(python3 -c "import json; print(json.load(open('$deploy_file'))['SP1_VERIFIER_GATEWAY_GROTH16'])")
  gw_plonk=$(python3 -c "import json; print(json.load(open('$deploy_file'))['SP1_VERIFIER_GATEWAY_PLONK'])")

  # Check Groth16 route
  g16_status=$(check_route "$gw_groth16" "$V6_GROTH16_SEL" "$rpc_url" "$V6_GROTH16")
  # Check Plonk route
  plonk_status=$(check_route "$gw_plonk" "$V6_PLONK_SEL" "$rpc_url" "$V6_PLONK")

  # Format output
  format_status() {
    local status="$1"
    case "$status" in
      REGISTERED) printf "${GREEN}%-15s${NC}" "REGISTERED" ;;
      NOT_REGISTERED) printf "${RED}%-15s${NC}" "NOT REGISTERED" ;;
      FROZEN) printf "${YELLOW}%-15s${NC}" "FROZEN" ;;
      WRONG:*) printf "${RED}%-15s${NC}" "WRONG ADDR" ;;
      ERROR) printf "${YELLOW}%-15s${NC}" "ERROR" ;;
    esac
  }

  printf "%-20s %-10s " "$chain_name" "$chain_id"
  format_status "$g16_status"
  printf " "
  format_status "$plonk_status"
  printf "\n"

  # Count
  total=$((total + 2))
  for s in "$g16_status" "$plonk_status"; do
    case "$s" in
      REGISTERED) registered=$((registered + 1)) ;;
      NOT_REGISTERED) not_registered=$((not_registered + 1)) ;;
      *) errors=$((errors + 1)) ;;
    esac
  done
done

printf "\n${BOLD}Summary${NC}\n"
printf "Total routes checked: %d\n" "$total"
printf "${GREEN}Registered: %d${NC}\n" "$registered"
printf "${RED}Not registered: %d${NC}\n" "$not_registered"
if [[ $errors -gt 0 ]]; then
  printf "${YELLOW}Errors/Other: %d${NC}\n" "$errors"
fi

if [[ $not_registered -eq 0 && $errors -eq 0 ]]; then
  printf "\n${GREEN}${BOLD}All v6.0.0 routes are registered.${NC}\n"
elif [[ $registered -eq 0 ]]; then
  printf "\n${RED}${BOLD}No v6.0.0 routes are registered yet (clean slate).${NC}\n"
fi
