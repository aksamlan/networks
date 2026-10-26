# worrell-testnet-2: genesis ceremony

`worrell-testnet-2` is a new network that starts the way mainnet will start: validators
send a signed genesis transaction (gentx) during a sign-up window, the final genesis file
is built from those transactions and published, and every node starts at the same time.

The purpose of this testnet is to rehearse that coordinated start. Governance, IBC and
coordinated upgrades were already exercised on `worrell-testnet-1`, which keeps running until
24 November 2026, two weeks after the start of this network. Activity on `worrell-testnet-1`
is recorded until that date.

Joining is open to every validator. There is no selection for this testnet. Participation
is recorded per operator (who signed up, who was online at launch, who stayed).

## Timeline (UTC)

| Step | When |
|------|------|
| Gentx window opens (`pre-genesis.json` published) | Tuesday 27 October 2026, 10:00 UTC |
| Gentx window closes | Friday 6 November 2026, 10:00 UTC |
| Final genesis published (with sha256 and peers) | Saturday 7 November 2026 |
| Network start (`genesis_time`) | Tuesday 10 November 2026, 08:00 UTC |
| `worrell-testnet-1` closes | Tuesday 24 November 2026 |

Dates are announced on Telegram ([t.me/worrellvalidators](https://t.me/worrellvalidators))
and in [GitHub Discussions](https://github.com/worrellchain/worrell/discussions). Only the
times in this document and in those announcements are authoritative.

## What you get and what you need

- Every account that submits a valid gentx receives **500 WORRELL** in the genesis, from the
  `incentives` account. Your gentx self-delegates part of it (between 1 and 500 WORRELL).
  Keep a few WORRELL liquid for fees: 495 is the suggested self-delegation.
- Binary: **v0.2.0** ([release](https://github.com/worrellchain/worrell/releases/tag/v0.2.0)).
  It is a packaging release of the code that runs on `worrell-testnet-1`: same consensus rules,
  statically linked binaries for every platform, and the same application name and version
  string whether you download it or build it with `make install`.
- A server that meets the testnet requirements of the
  [validator guide](https://github.com/worrellchain/worrell/blob/main/docs/RUNNING-A-NODE.md).
- A GitHub account, to open the pull request with your gentx.

## Network parameters

Same as mainnet, with one exception: the unbonding period is 3 days instead of 21.

| Parameter | Value |
|-----------|-------|
| Chain ID | `worrell-testnet-2` |
| Denomination | `uworrell` (1 WORRELL = 1,000,000 uworrell) |
| Unbonding period | 3 days |
| Downtime jail duration | 12 hours |
| Governance: deposit period / voting period / expedited | 14 days / 7 days / 24 hours |
| Min commission rate | 5% |
| Max validators | 100 |
| IBC | closed at genesis (no light clients allowed, transfers disabled, interchain accounts host disabled) |
| Minimum gas price | `0.025uworrell` |
| Faucet | 100 WORRELL per request; one request per address, at most 3 per IP and 300 in total every 24 hours (address published at launch). Tokens obtained from the faucet carry no weight in anything: there is no founder delegation on this testnet and participation is recorded per operator, not per stake |

## Step 1. Install worrelld v0.2.0

Follow section 2 of the [validator guide](https://github.com/worrellchain/worrell/blob/main/docs/RUNNING-A-NODE.md)
with version `v0.2.0`. Checksums of the release tarballs (from the `release_checksum` file
published with the release):

| Tarball | sha256 |
|---------|--------|
| `v0.2.0_linux_amd64.tar.gz` | `1ccccd39d57467236a2f64ee4809fee4de3cc3f1bc02c47e3e22aa9c6b414c76` |
| `v0.2.0_linux_arm64.tar.gz` | `e4ad1e1bef4aa4656d03a543076d4cc08f91114a1cf93454218063f05992fb52` |
| `v0.2.0_darwin_arm64.tar.gz` | `8e87a7fa71b573467f3790c25207e0ba50bc8f5a5d7ecc2f328c691c31fbaff6` |
| `v0.2.0_darwin_amd64.tar.gz` | `841904a222bc7995362aba877479846ba459c14ff26e15a3754414c9a04a0e05` |

All four binaries are statically linked: they need no system libraries and run on any 64-bit
Linux or on macOS 12 or newer. Use the same binary (prebuilt or built from the `v0.2.0` tag)
for the gentx and for running the node afterwards.

```bash
worrelld version    # v0.2.0
```

## Step 2. Initialize a separate home for this network

If this server already runs a `worrell-testnet-1` node, do **not** reuse its `~/.worrell`
folder. Give the new network its own home and pass `--home` to every command below.
The two nodes also need different ports (see "Running next to a testnet-1 node").

```bash
export T2_HOME=$HOME/.worrell-testnet-2
worrelld init <moniker> --chain-id worrell-testnet-2 --default-denom uworrell --home $T2_HOME
```

`<moniker>` is the public name of your validator. This creates `priv_validator_key.json`
(your consensus key) and `node_key.json` in `$T2_HOME/config/`. The gentx you sign in step 4
contains this consensus key: keep this home folder, and back up `priv_validator_key.json`.

Recommended: replace the genesis created by `init` with the published
[`pre-genesis.json`](pre-genesis.json). It is the real genesis of the network without the
operators' accounts and gentx (founder and multisig accounts, module parameters, the
founder's gentx), so you can review the parameters and prepare your gentx against the
actual configuration. The final genesis is this file plus the accepted gentx and their accounts.

```bash
curl -s https://raw.githubusercontent.com/worrellchain/networks/main/worrell-testnet-2/pre-genesis.json \
  -o $T2_HOME/config/genesis.json
sha256sum $T2_HOME/config/genesis.json
# f5231dc924c762bdbe5aa0605ed6472288c9b71f4b175015e0559edccdd96b94
```

Either way (pre-genesis or the genesis from `init --default-denom uworrell`) the gentx is the
same; the local genesis is only used to build it.

## Step 3. Create the operator account

```bash
worrelld keys add <key-name> --home $T2_HOME
worrelld keys show <key-name> -a --home $T2_HOME     # worrell1...
```

Write down the mnemonic. This account receives the 500 WORRELL in the genesis and is the
account your gentx is signed with. One gentx per account; a second gentx from the same
account is rejected.

Add the account to your local copy of the genesis with the amount you will receive. This
local genesis is only used to build the gentx; it is replaced by the published one later.

```bash
worrelld genesis add-genesis-account $(worrelld keys show <key-name> -a --home $T2_HOME) \
  500000000uworrell --home $T2_HOME
```

## Step 4. Create the gentx

```bash
worrelld genesis gentx <key-name> 495000000uworrell \
  --chain-id worrell-testnet-2 \
  --moniker "<moniker>" \
  --commission-rate 0.05 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1000000 \
  --ip <your public IP> \
  --p2p-port 26656 \
  --home $T2_HOME
# optional: --website "https://..." --details "..." --identity <keybase id>
```

- The amount is your self-delegation: between `1000000uworrell` (1 WORRELL) and
  `500000000uworrell` (500 WORRELL). Anything above 500 is rejected.
- `--chain-id` must be exactly `worrell-testnet-2`. A gentx signed for another chain ID looks
  valid but makes the whole network fail at start, so it is excluded (see step 6).
- `--commission-rate` must be at least `0.05` (the network minimum).
- `--ip` and `--p2p-port` go into the memo of the transaction (`nodeid@ip:port`) and are
  published as peers, so use the address other nodes can reach.

The file is written to `$T2_HOME/config/gentx/gentx-<node id>.json`. Check it:

```bash
cat $T2_HOME/config/gentx/gentx-*.json | jq '.body.messages[0] | {moniker: .description.moniker, validator_address, value}'
```

## Step 5. Submit the gentx (pull request)

1. Fork [worrellchain/networks](https://github.com/worrellchain/networks).
2. Copy your file to `worrell-testnet-2/gentx/<moniker>.json` (use your moniker as the file name).
3. Open a pull request titled `gentx: <moniker>`. One file per pull request.

The pull request must arrive before the window closes. Each file is checked for:

- exactly one `MsgCreateValidator` message and one signature;
- denomination `uworrell` and amount between 1 and 500 WORRELL;
- an account that is not already used by another gentx and is not a founder account;
- a valid JSON file.

A pull request that fails a check is closed with the reason, and you can open a new one
within the window. Merged pull requests are not edited afterwards: if you need to change
something, open a new pull request and say which one it replaces.

## Step 6. After the window: the final genesis

When the window closes, the coordinator builds the genesis: every gentx account is credited
with 500 WORRELL from `incentives`, the gentx files are collected, the module parameters are
applied and the total supply is verified (exactly 1,000,000,000 WORRELL).

The genesis is then started on a local test node. Signatures are only verified at that point:
a gentx signed for the wrong chain ID or with the wrong account stops the chain at block 0
with `signature verification failed`. Such a gentx is removed, the operator is informed, and
the genesis is rebuilt. An excluded operator can still join after launch with a normal
`create-validator` transaction, funded by the faucet.

Only after that test the final `genesis.json` is published in this folder, together with its
sha256 and the list of persistent peers taken from the gentx memos. The hash is posted on
Telegram and in GitHub Discussions.

## Step 7. Before the start

```bash
curl -s https://raw.githubusercontent.com/worrellchain/networks/main/worrell-testnet-2/genesis.json \
  -o $T2_HOME/config/genesis.json
sha256sum $T2_HOME/config/genesis.json     # must match the published hash
```

Edit `$T2_HOME/config/config.toml` and `$T2_HOME/config/app.toml`:

```toml
# config.toml -> [p2p]
persistent_peers = "4ae3601a733c88a1b8f377774ff197dbd3e377c6@144.91.82.147:26656"
# app.toml
minimum-gas-prices = "0.025uworrell"
```

The peer above is the founder's node. The full list of peers, taken from the gentx memos, is
published together with the final genesis; add them to `persistent_peers` as well.

Do not touch `priv_validator_key.json`: it must be the key your gentx was created with.
Cosmovisor is recommended but not required for the start.

Start the node a few minutes before `genesis_time`:

```bash
worrelld start --home $T2_HOME
```

A node started before `genesis_time` waits, then produces the first block together with the
other genesis validators. Nothing happens before that time, which is normal.

## Step 8. After the start

```bash
worrelld status --home $T2_HOME | jq '.sync_info | {latest_block_height, catching_up}'
worrelld q staking validator $(worrelld keys show <key-name> --bech val -a --home $T2_HOME) --home $T2_HOME
```

Your validator should be `BOND_STATUS_BONDED` from block 1. Who was online at the start,
who joined late and who did not appear is recorded per operator.

## Running next to a testnet-1 node

Both networks can share a server. Keep separate homes (`~/.worrell` and
`~/.worrell-testnet-2`) and change the ports of the new node in `$T2_HOME/config/config.toml`
and `app.toml` so they do not collide: P2P (26656), RPC (26657), ABCI (26658), pprof (6060),
gRPC (9090) and API (1317). If you move the P2P port, use the same value in `--p2p-port`
when creating the gentx.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `signature verification failed` at start, chain does not move | A gentx in the genesis was signed for another chain ID or account. The coordinator removes it and republishes; do not start with an unpublished genesis. |
| Genesis sha256 does not match | Download again from this repository; do not edit the file. |
| Node starts but does nothing before launch | Expected: it waits for `genesis_time`. |
| `account ... does not exist` when running `gentx` | Run `add-genesis-account` first (step 3), in the same home. |
| `the provided denom ... does not match` | Initialize with `--default-denom uworrell` (step 2). |
| Address already in use | Another node (testnet-1) uses the same ports; see the section above. |

## Contents of this folder

- `README.md`: this guide.
- `pre-genesis.json`: the genesis without the operators' gentx, published when the window opens.
- `gentx/`: gentx files submitted by pull request during the window.
- `setup-genesis.sh` and `setup-multisig.sh`: scripts used by the coordinator to build the genesis
  (not needed to join; do not run them).
- `genesis.json`, `chain.json`, `assetlist.json`: added when the final genesis is published and
  after the start.

## Questions

[GitHub Discussions](https://github.com/worrellchain/worrell/discussions) or hello@worrellchain.com.
