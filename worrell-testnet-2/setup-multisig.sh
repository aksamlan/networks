#!/usr/bin/env bash
#
# Worrell mainnet — setup-multisig.sh
# Creates the signer keys, the auxiliary keys and the 4 multisig accounts.
#
#   treasury    3 of 3   henry, george, charlie                  (unanimity)
#   airdrop     2 of 4   henry, george, charlie, airdrop-aux     (2 of the 3 founders)
#   incentives  2 of 4   henry, george, charlie, incentives-aux  (2 of the 3 founders)
#   reserve     2 of 4   henry, george, charlie, reserve-aux     (2 of the 3 founders)
#
# The auxiliary keys (*-aux) exist ONLY to produce a distinct multisig
# address; they do NOT take part in the actual signing (the threshold is 2, reachable only by
# the founders). In a real launch each founder generates their key
# securely (hardware wallet) and shares only the pubkey; this script creates them
# locally for rehearsal/dev.
#
# Idempotent: if a key already exists in the keyring, it is not recreated.
#
# Environment variables (with defaults):
#   HOME_DIR          data directory (default ~/.worrell)
#   KEYRING_BACKEND   os | file | test  (default test, for local rehearsal)
#   WORRELLD          path to the binary (default worrelld in PATH)
#   MNEMONICS_FILE    where the recovery phrases of NEW keys are appended
#                     (default $HOME_DIR/mnemonics.txt, mode 600). A recovery phrase is
#                     only shown once, when the key is created: copy this file to a safe
#                     place and delete it from the server.
#
set -euo pipefail

WORRELLD="${WORRELLD:-worrelld}"
HOME_DIR="${HOME_DIR:-$HOME/.worrell}"
KEYRING_BACKEND="${KEYRING_BACKEND:-test}"
MNEMONICS_FILE="${MNEMONICS_FILE:-$HOME_DIR/mnemonics.txt}"

KB=(--keyring-backend "$KEYRING_BACKEND" --home "$HOME_DIR")

# Creates a normal key if it does not already exist, saving its recovery phrase.
ensure_key() {
  local name="$1" out
  if "$WORRELLD" keys show "$name" "${KB[@]}" >/dev/null 2>&1; then
    echo "  · key '$name' already exists, keeping it"
  else
    out=$("$WORRELLD" keys add "$name" --output json "${KB[@]}" 2>&1)
    mkdir -p "$(dirname "$MNEMONICS_FILE")"
    ( umask 077; touch "$MNEMONICS_FILE" )
    chmod 600 "$MNEMONICS_FILE"
    {
      echo "key: $name"
      echo "address: $(echo "$out" | jq -r '.address')"
      echo "mnemonic: $(echo "$out" | jq -r '.mnemonic')"
      echo
    } >> "$MNEMONICS_FILE"
    echo "  + key '$name' created (recovery phrase appended to $MNEMONICS_FILE)"
  fi
}

# Creates a multisig account if it does not already exist.
ensure_multisig() {
  local name="$1"; local threshold="$2"; local signers="$3"
  if "$WORRELLD" keys show "$name" "${KB[@]}" >/dev/null 2>&1; then
    echo "  · multisig '$name' already exists, keeping it"
  else
    "$WORRELLD" keys add "$name" \
      --multisig "$signers" --multisig-threshold "$threshold" \
      --nosort "${KB[@]}" >/dev/null 2>&1
    echo "  + multisig '$name' ($threshold of N) created: signers=$signers"
  fi
}

echo "==> Keyring backend: $KEYRING_BACKEND   Home: $HOME_DIR"

echo "==> Founder keys"
ensure_key henry
ensure_key george
ensure_key charlie

echo "==> Auxiliary keys (only to generate distinct multisig addresses)"
ensure_key airdrop-aux
ensure_key incentives-aux
ensure_key reserve-aux

echo "==> Multisig accounts"
ensure_multisig treasury   3 "henry,george,charlie"
ensure_multisig airdrop    2 "henry,george,charlie,airdrop-aux"
ensure_multisig incentives 2 "henry,george,charlie,incentives-aux"
ensure_multisig reserve    2 "henry,george,charlie,reserve-aux"

echo "==> Generated addresses"
for acc in henry george charlie treasury airdrop incentives reserve; do
  addr=$("$WORRELLD" keys show "$acc" -a "${KB[@]}")
  printf "  %-12s %s\n" "$acc" "$addr"
done

echo "==> Multisig ready."
if [ -s "$MNEMONICS_FILE" ]; then
  echo "==> Recovery phrases of the keys created in this run are in $MNEMONICS_FILE (mode 600)."
  echo "    Copy them to a safe place and delete the file from this machine."
fi
