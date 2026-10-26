#!/usr/bin/env bash
#
# Worrell testnet-2 — setup-genesis.sh
# Builds the worrell-testnet-2 genesis for the genesis ceremony (multi-validator start
# with gentx files collected from the operators).
#
# Differences with worrell-testnet-1:
#   * mainnet times, except unbonding (3 days instead of 21)
#   * voting period 7 days
#   * IBC fully closed at genesis: no allowed light clients, transfers disabled,
#     interchain-accounts host disabled (governance opens them when needed)
#   * evidence max age aligned with the unbonding period
#   * token metadata (uworrell / WORRELL, 6 decimals) in the bank module
#   * every operator that sends a gentx receives ALLOCATION uworrell from `incentives`
#   * the vesting founders (henry, charlie) also get FOUNDER_LIQUID uworrell liquid,
#     from `incentives`, so nobody starts with zero spendable balance
#
# The faucet (george, 100 WORRELL per request, once a day per address) is NOT part of
# the genesis: it is a separate service.
#
# It reuses the key/multisig creator (setup-multisig.sh, in this same folder).
# The keyring is KEPT between runs, so the founder and multisig addresses do not change
# between the pre-genesis (run without GENTX_DIR) and the final genesis (run with it).
#
# Environment variables (with defaults):
#   HOME_DIR          node home                              (default ~/.worrell-testnet-2)
#   KEYRING_BACKEND   os | file | test                       (default test)
#   GENESIS_TIME_UNIX genesis epoch, UTC                     (default: now)
#   WORRELLD          path to the binary                     (default worrelld)
#   GENTX_DIR         folder with the operators' gentx files (default: none → pre-genesis)
#   ALLOCATION        uworrell credited to each gentx account (default 500000000 = 500 WORRELL)
#   FOUNDER_LIQUID    liquid uworrell for each vesting founder (default 5000000 = 5 WORRELL)
#   HENRY_IP          IP or hostname written in henry's gentx memo (default: autodetected)
#   RESET_DATA        yes → wipe an existing data/ folder (previous rehearsal)
#
set -euo pipefail

WORRELLD="${WORRELLD:-worrelld}"
HOME_DIR="${HOME_DIR:-$HOME/.worrell-testnet-2}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"
GENESIS_TIME_UNIX="${GENESIS_TIME_UNIX:-$(date +%s)}"
GENTX_DIR="${GENTX_DIR:-}"
ALLOCATION="${ALLOCATION:-500000000}"
FOUNDER_LIQUID="${FOUNDER_LIQUID:-5000000}"
HENRY_IP="${HENRY_IP:-}"
RESET_DATA="${RESET_DATA:-no}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MULTISIG_SCRIPT="$SCRIPT_DIR/setup-multisig.sh"

CHAIN_ID="worrell-testnet-2"
MONIKER="henry"
DENOM="uworrell"

# --- Times (mainnet values, except UNBONDING) ---
UNBONDING="259200s"      # 3 days  (mainnet: 1814400s = 21 days)
JAIL="43200s"            # 12 hours
DEP_PERIOD="1209600s"    # 14 days
VOTING="604800s"         # 7 days
EXP_VOTING="86400s"      # 24 hours

# --- Evidence (CometBFT consensus params), aligned with UNBONDING ---
EVIDENCE_MAX_AGE_DURATION="259200000000000"   # 3 days in nanoseconds (mainnet: 1814400000000000)
EVIDENCE_MAX_AGE_BLOCKS="100000"              # generous for 3 days at ~5 s/block (mainnet: 1000000)

# --- Vesting anchor (same offsets as mainnet) ---
VESTING_START=$((GENESIS_TIME_UNIX + 31557600))   # genesis + 1 year
VESTING_END=$((GENESIS_TIME_UNIX + 126230400))    # genesis + 4 years

# --- Amounts (uworrell) ---
HENRY_TOTAL=100000000000000
GEORGE_TOTAL=50000000000000
CHARLIE_TOTAL=50000000000000
TREASURY=300000000000000
AIRDROP=225000000000000
INCENTIVES=175000000000000
RESERVE=100000000000000
SELF_DELEGATION=20000000000000
MIN_SELF_DELEGATION=1000000
TOTAL_SUPPLY=1000000000000000

KB=(--keyring-backend "$KEYRING_BACKEND" --home "$HOME_DIR")
GENESIS="$HOME_DIR/config/genesis.json"
GENTX_OUT="$HOME_DIR/config/gentx"

to_iso() {
  date -u -d "@$1" +%Y-%m-%dT%H:%M:%S.000000000Z 2>/dev/null \
    || date -u -r "$1" +%Y-%m-%dT%H:%M:%S.000000000Z
}

die() { echo "ERROR: $*" >&2; exit 1; }

# valoper (worrellvaloper1...) → account address (worrell1...), same key bytes.
valoper_to_account() {
  local hex
  hex=$("$WORRELLD" keys parse "$1" --output json 2>/dev/null | jq -r '.bytes')
  [ -n "$hex" ] && [ "$hex" != "null" ] || die "cannot decode validator address $1"
  "$WORRELLD" keys parse "$hex" --output json 2>/dev/null \
    | jq -r '.formats[]' | grep -E '^worrell1[a-z0-9]{38}$' | head -1
}

# ----------------------------------------------------------------------------------
echo "==> [0/7] safety checks"
command -v jq >/dev/null || die "jq is required"
"$WORRELLD" version >/dev/null 2>&1 || die "binary not found: $WORRELLD"
if [ -f "$GENESIS" ]; then
  existing=$(jq -r '.chain_id' "$GENESIS")
  [ "$existing" = "$CHAIN_ID" ] \
    || die "$HOME_DIR already holds a genesis for '$existing'. Refusing to touch it. Use another HOME_DIR."
fi
if [ -f "$HOME_DIR/data/blockstore.db/CURRENT" ]; then
  [ "$RESET_DATA" = "yes" ] \
    || die "$HOME_DIR/data has chain data (a node ran here). Re-run with RESET_DATA=yes to wipe it."
  "$WORRELLD" comet unsafe-reset-all --home "$HOME_DIR" >/dev/null 2>&1
  echo "  · data/ reset"
fi
if [ -n "$GENTX_DIR" ]; then
  [ -d "$GENTX_DIR" ] || die "GENTX_DIR does not exist: $GENTX_DIR"
  ls "$GENTX_DIR"/*.json >/dev/null 2>&1 || die "no *.json files in $GENTX_DIR"
fi

echo "==> [1/7] init ($CHAIN_ID) — keyring and node keys are kept if they exist"
"$WORRELLD" init "$MONIKER" --chain-id "$CHAIN_ID" --default-denom "$DENOM" \
  --home "$HOME_DIR" -o >/dev/null 2>&1
rm -rf "$GENTX_OUT"; mkdir -p "$GENTX_OUT"

echo "==> [2/7] keys and multisig"
HOME_DIR="$HOME_DIR" KEYRING_BACKEND="$KEYRING_BACKEND" WORRELLD="$WORRELLD" \
  bash "$MULTISIG_SCRIPT"

A_HENRY=$("$WORRELLD" keys show henry -a "${KB[@]}")
A_GEORGE=$("$WORRELLD" keys show george -a "${KB[@]}")
A_CHARLIE=$("$WORRELLD" keys show charlie -a "${KB[@]}")
A_TREASURY=$("$WORRELLD" keys show treasury -a "${KB[@]}")
A_AIRDROP=$("$WORRELLD" keys show airdrop -a "${KB[@]}")
A_INCENTIVES=$("$WORRELLD" keys show incentives -a "${KB[@]}")
A_RESERVE=$("$WORRELLD" keys show reserve -a "${KB[@]}")

# ----------------------------------------------------------------------------------
echo "==> [3/7] operator gentx files"
OPERATORS=0
PEERS=()
OP_LINES=()
SEEN=""
if [ -n "$GENTX_DIR" ]; then
  for f in "$GENTX_DIR"/*.json; do
    name=$(basename "$f")
    nmsg=$(jq '.body.messages | length' "$f")
    [ "$nmsg" = "1" ] || die "$name: expected exactly 1 message, found $nmsg"
    mtype=$(jq -r '.body.messages[0]."@type"' "$f")
    [ "$mtype" = "/cosmos.staking.v1beta1.MsgCreateValidator" ] || die "$name: unexpected message $mtype"
    nsig=$(jq '.signatures | length' "$f")
    [ "$nsig" = "1" ] || die "$name: expected 1 signature, found $nsig"
    valoper=$(jq -r '.body.messages[0].validator_address' "$f")
    amount=$(jq -r '.body.messages[0].value.amount' "$f")
    denom=$(jq -r '.body.messages[0].value.denom' "$f")
    moniker=$(jq -r '.body.messages[0].description.moniker' "$f")
    memo=$(jq -r '.body.memo' "$f")
    [ "$denom" = "$DENOM" ] || die "$name ($moniker): denom $denom, expected $DENOM"
    [ "$amount" -le "$ALLOCATION" ] 2>/dev/null \
      || die "$name ($moniker): self-delegation $amount exceeds the allocation $ALLOCATION"
    [ "$amount" -ge "$MIN_SELF_DELEGATION" ] 2>/dev/null \
      || die "$name ($moniker): self-delegation $amount below the minimum $MIN_SELF_DELEGATION"
    acc=$(valoper_to_account "$valoper")
    [ -n "$acc" ] || die "$name ($moniker): cannot derive the account address from $valoper"
    for founder in "$A_HENRY" "$A_GEORGE" "$A_CHARLIE"; do
      [ "$acc" != "$founder" ] || die "$name ($moniker): account $acc is a founder account"
    done
    case " $SEEN " in *" $acc "*) die "$name ($moniker): account $acc appears in more than one gentx";; esac
    SEEN="$SEEN $acc"
    "$WORRELLD" genesis add-genesis-account "$acc" "${ALLOCATION}${DENOM}" "${KB[@]}"
    cp "$f" "$GENTX_OUT/"
    OPERATORS=$((OPERATORS + 1))
    OP_LINES+=("$(printf "   %-24s %s  self-delegation %s  %s" "$moniker" "$acc" "$amount" "$memo")")
    if [ -n "$memo" ] && [ "$memo" != "null" ]; then PEERS+=("$memo"); fi
  done
  echo "  · $OPERATORS operator gentx accepted"
else
  echo "  · no GENTX_DIR: building the PRE-GENESIS (henry only)"
fi

INCENTIVES_LEFT=$((INCENTIVES - OPERATORS * ALLOCATION - 2 * FOUNDER_LIQUID))
[ "$INCENTIVES_LEFT" -gt 0 ] || die "incentives would go negative"

# ----------------------------------------------------------------------------------
echo "==> [4/7] genesis accounts (founders with continuous vesting + liquid margin, community multisig)"
"$WORRELLD" genesis add-genesis-account "$A_HENRY" "$((HENRY_TOTAL + FOUNDER_LIQUID))${DENOM}" \
  --vesting-amount "${HENRY_TOTAL}${DENOM}" \
  --vesting-start-time "$VESTING_START" --vesting-end-time "$VESTING_END" "${KB[@]}"
# george: NO vesting on testnet so it can operate the faucet. In mainnet (no faucet)
# george is vesting too, with the same liquid margin as the other founders.
"$WORRELLD" genesis add-genesis-account "$A_GEORGE" "${GEORGE_TOTAL}${DENOM}" "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_CHARLIE" "$((CHARLIE_TOTAL + FOUNDER_LIQUID))${DENOM}" \
  --vesting-amount "${CHARLIE_TOTAL}${DENOM}" \
  --vesting-start-time "$VESTING_START" --vesting-end-time "$VESTING_END" "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_TREASURY"   "${TREASURY}${DENOM}"        "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_AIRDROP"    "${AIRDROP}${DENOM}"         "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_INCENTIVES" "${INCENTIVES_LEFT}${DENOM}" "${KB[@]}"
"$WORRELLD" genesis add-genesis-account "$A_RESERVE"    "${RESERVE}${DENOM}"         "${KB[@]}"

GTS="$(to_iso "$GENESIS_TIME_UNIX")"
tmp=$(mktemp); jq --arg ts "$GTS" '.genesis_time = $ts' "$GENESIS" > "$tmp" && mv "$tmp" "$GENESIS"

# ----------------------------------------------------------------------------------
echo "==> [5/7] henry gentx (self-delegation ${SELF_DELEGATION}${DENOM} = 20M) and collect"
IPFLAG=()
if [ -n "$HENRY_IP" ]; then IPFLAG=(--ip "$HENRY_IP"); fi
"$WORRELLD" genesis gentx henry "${SELF_DELEGATION}${DENOM}" \
  --chain-id "$CHAIN_ID" \
  --commission-rate "0.05" \
  --commission-max-rate "0.25" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "$MIN_SELF_DELEGATION" "${IPFLAG[@]}" "${KB[@]}" >/dev/null 2>&1
"$WORRELLD" genesis collect-gentxs --home "$HOME_DIR" >/dev/null 2>&1

# ----------------------------------------------------------------------------------
echo "==> [6/7] module parameters, IBC closed, evidence, token metadata, block gas limit"
tmp=$(mktemp)
jq \
  --arg unbonding "$UNBONDING" --arg jail "$JAIL" \
  --arg dep "$DEP_PERIOD" --arg voting "$VOTING" --arg exp "$EXP_VOTING" \
  --arg evd "$EVIDENCE_MAX_AGE_DURATION" --arg evb "$EVIDENCE_MAX_AGE_BLOCKS" \
  '
  .consensus.params.block.max_gas = "40000000"
  | .consensus.params.evidence.max_age_duration = $evd
  | .consensus.params.evidence.max_age_num_blocks = $evb
  | .app_state.staking.params.bond_denom = "uworrell"
  | .app_state.staking.params.unbonding_time = $unbonding
  | .app_state.staking.params.max_validators = 100
  | .app_state.staking.params.max_entries = 7
  | .app_state.staking.params.historical_entries = 10000
  | .app_state.staking.params.min_commission_rate = "0.050000000000000000"
  | .app_state.mint.minter.inflation = "0.130000000000000000"
  | .app_state.mint.params.mint_denom = "uworrell"
  | .app_state.mint.params.inflation_rate_change = "0.130000000000000000"
  | .app_state.mint.params.inflation_max = "0.130000000000000000"
  | .app_state.mint.params.inflation_min = "0.070000000000000000"
  | .app_state.mint.params.goal_bonded = "0.670000000000000000"
  | .app_state.mint.params.blocks_per_year = "6311520"
  | .app_state.slashing.params.signed_blocks_window = "10000"
  | .app_state.slashing.params.min_signed_per_window = "0.050000000000000000"
  | .app_state.slashing.params.downtime_jail_duration = $jail
  | .app_state.slashing.params.slash_fraction_double_sign = "0.050000000000000000"
  | .app_state.slashing.params.slash_fraction_downtime = "0.000100000000000000"
  | .app_state.distribution.params.community_tax = "0.100000000000000000"
  | .app_state.gov.params.min_deposit = [{"denom":"uworrell","amount":"1500000000"}]
  | .app_state.gov.params.max_deposit_period = $dep
  | .app_state.gov.params.voting_period = $voting
  | .app_state.gov.params.quorum = "0.334000000000000000"
  | .app_state.gov.params.threshold = "0.500000000000000000"
  | .app_state.gov.params.veto_threshold = "0.334000000000000000"
  | .app_state.gov.params.burn_vote_quorum = true
  | .app_state.gov.params.burn_proposal_deposit_prevote = false
  | .app_state.gov.params.burn_vote_veto = true
  | .app_state.gov.params.expedited_min_deposit = [{"denom":"uworrell","amount":"7500000000"}]
  | .app_state.gov.params.expedited_voting_period = $exp
  | .app_state.gov.params.expedited_threshold = "0.667000000000000000"
  | .app_state.ibc.client_genesis.params.allowed_clients = []
  | .app_state.transfer.params.send_enabled = false
  | .app_state.transfer.params.receive_enabled = false
  | .app_state.interchainaccounts.host_genesis_state.params.host_enabled = false
  | .app_state.interchainaccounts.host_genesis_state.params.allow_messages = []
  | .app_state.bank.denom_metadata = [{
      "description": "The native token of Worrell.",
      "denom_units": [
        {"denom": "uworrell", "exponent": 0, "aliases": ["microworrell"]},
        {"denom": "WORRELL", "exponent": 6, "aliases": []}
      ],
      "base": "uworrell",
      "display": "WORRELL",
      "name": "Worrell",
      "symbol": "WORRELL",
      "uri": "",
      "uri_hash": ""
    }]
  ' "$GENESIS" > "$tmp" && mv "$tmp" "$GENESIS"

# ----------------------------------------------------------------------------------
echo "==> [7/7] validation"
"$WORRELLD" genesis validate-genesis --home "$HOME_DIR"
supply=$(jq -r '.app_state.bank.supply[] | select(.denom=="uworrell") | .amount' "$GENESIS")
[ "$supply" = "$TOTAL_SUPPLY" ] || die "total supply is $supply, expected $TOTAL_SUPPLY"
balances_sum=$(jq '[.app_state.bank.balances[].coins[] | select(.denom=="uworrell") | .amount | tonumber] | add' "$GENESIS")
[ "$balances_sum" = "$TOTAL_SUPPLY" ] || die "sum of balances is $balances_sum, expected $TOTAL_SUPPLY"
ngentx=$(jq '.app_state.genutil.gen_txs | length' "$GENESIS")
[ "$ngentx" = "$((OPERATORS + 1))" ] || die "genesis holds $ngentx gentx, expected $((OPERATORS + 1))"
if command -v sha256sum >/dev/null; then SHA=$(sha256sum "$GENESIS" | cut -d' ' -f1)
else SHA=$(shasum -a 256 "$GENESIS" | cut -d' ' -f1); fi

kind="FINAL GENESIS"
PRE_GENESIS_COPY=""
if [ "$OPERATORS" = "0" ]; then
  kind="PRE-GENESIS (henry only)"
  # Copy published at the opening of the gentx window, next to this script, so operators can
  # review the parameters and use it as their local genesis when creating the gentx.
  PRE_GENESIS_COPY="$SCRIPT_DIR/pre-genesis.json"
  if cp "$GENESIS" "$PRE_GENESIS_COPY" 2>/dev/null; then
    echo "  · pre-genesis copied to $PRE_GENESIS_COPY"
  else
    PRE_GENESIS_COPY="$HOME_DIR/pre-genesis.json"; cp "$GENESIS" "$PRE_GENESIS_COPY"
    echo "  · script folder not writable; pre-genesis copied to $PRE_GENESIS_COPY"
  fi
fi
cat <<EOF

============ $kind $CHAIN_ID READY ============
 genesis_time : $GTS
 Times        : unbonding $UNBONDING | jail $JAIL | deposit $DEP_PERIOD | voting $VOTING | expedited $EXP_VOTING
 Evidence     : max_age $EVIDENCE_MAX_AGE_DURATION ns / $EVIDENCE_MAX_AGE_BLOCKS blocks
 IBC          : closed (allowed_clients [], transfer off, ICA host off)
 Total supply : 1,000,000,000 WORRELL ($TOTAL_SUPPLY uworrell) — verified
 Operators    : $OPERATORS gentx, $ALLOCATION uworrell each from incentives
 Incentives   : $INCENTIVES_LEFT uworrell left in the genesis
 Gentx total  : $ngentx (henry + operators)
 Genesis at   : $GENESIS${PRE_GENESIS_COPY:+
 Pre-genesis  : $PRE_GENESIS_COPY (publish this file when the gentx window opens)}
 sha256       : $SHA
 Accounts     :
   henry      $A_HENRY
   george     $A_GEORGE
   charlie    $A_CHARLIE
   treasury   $A_TREASURY
   airdrop    $A_AIRDROP
   incentives $A_INCENTIVES
   reserve    $A_RESERVE
EOF
if [ "$OPERATORS" -gt 0 ]; then
  echo " Operators (moniker, account, self-delegation, peer from gentx memo):"
  printf '%s\n' "${OP_LINES[@]}"
  echo " Peers from gentx memos (for chain.json / persistent_peers):"
  printf '   %s\n' "${PEERS[@]}"
fi
echo "========================================================================"
echo "NOTE: gentx signatures are only verified when the chain starts (InitChain)."
echo "      Before publishing a final genesis, start a node with it locally and check that"
echo "      InitChain completes without errors."
