# Worrell — Networks

Public configuration for the Worrell blockchain networks, following the
[Cosmos Chain Registry](https://github.com/cosmos/chain-registry) format.

The node source code (`worrelld`) is in
[worrellchain/worrell](https://github.com/worrellchain/worrell).

## Networks

| Network | Folder | Chain ID | Status |
|---------|--------|----------|--------|
| Testnet 1 | [`worrell-testnet-1/`](worrell-testnet-1/) | `worrell-testnet-1` | Active until 24 November 2026 |
| Testnet 2 | [`worrell-testnet-2/`](worrell-testnet-2/) | `worrell-testnet-2` | Genesis ceremony (see the [guide](worrell-testnet-2/README.md)) |

## worrell-testnet-2: genesis ceremony

`worrell-testnet-2` starts the way mainnet will: validators submit a gentx during a sign-up
window, the final genesis is published with its sha256, and every node starts at the same
time. Joining is open to every validator. Dates (UTC), parameters and the step-by-step
procedure are in [`worrell-testnet-2/README.md`](worrell-testnet-2/README.md). Gentx files go
to [`worrell-testnet-2/gentx/`](worrell-testnet-2/gentx/) by pull request (window: 27 October
to 6 November 2026, 10:00 UTC; network start: 10 November 2026, 08:00 UTC). `worrell-testnet-1`
keeps running until 24 November 2026.

## Join worrell-testnet-1

| Field | Value |
|-------|-------|
| Chain ID | `worrell-testnet-1` |
| Binary | `worrelld` (Cosmos SDK v0.53.6) |
| Source / version | [worrellchain/worrell](https://github.com/worrellchain/worrell) @ `v0.1.3` ([prebuilt binaries](https://github.com/worrellchain/worrell/releases/tag/v0.1.3)) since block `1186000` (upgrade of 13 October 2026). A node syncing from genesis must run `v0.1.2` until that height and then switch to `v0.1.3`; see the [upgrade guide](https://github.com/worrellchain/worrell/blob/main/docs/UPGRADES.md). Nodes that use State Sync from a recent snapshot start directly with `v0.1.3`. `v0.2.0` (a packaging release with the same consensus rules: static binaries, unified application name) is also compatible and can replace `v0.1.3` at any time, without a coordinated upgrade |
| Genesis | [`worrell-testnet-1/genesis.json`](worrell-testnet-1/genesis.json) |
| Genesis sha256 | `a81c507b12ba0678c3172394ff4bb03e1c3db60050cc5568c127a24ec19378fd` |
| Persistent peer | `bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656` |
| Min gas price | `0.025uworrell` |
| Faucet | `POST http://164.68.98.186:4500` with `{"address":"worrell1..."}` (500 WORRELL) |
| Validator announcements | Telegram [t.me/worrellvalidators](https://t.me/worrellvalidators) — upgrades, governance, coordination |
| Explorers | [test.anode.team/worrell](https://test.anode.team/worrell) (community-run by [ANODE.TEAM](https://anode.team)) · [explorer.oshvank.xyz/worrel-testnet](https://explorer.oshvank.xyz/worrel-testnet) (community-run by [OshVanK](https://oshvank.xyz)) · [explorer.husonode.xyz/Worrell-Testnet](https://explorer.husonode.xyz/Worrell-Testnet) (community-run by [HusoNode](https://husonode.xyz)) · [explorer.nodesync.top/Worrell-Testnet](https://explorer.nodesync.top/Worrell-Testnet) (community-run by [NODESYNC](https://nodesync.top)) · [explorer.bonynode.online/worrell-testnet](https://explorer.bonynode.online/worrell-testnet) (community-run by [BonyNode](https://bonynode.online)) · [explorer.sychonix.com/Worrell-Testnet](https://explorer.sychonix.com/Worrell-Testnet) (community-run by [Sychonix](https://sychonix.com)) · [explorer.onenov.xyz/worrell-testnet](https://explorer.onenov.xyz/worrell-testnet) (community-run by [OneNov](https://onenov.xyz)) · [explorer.codeblocklabs.com/worrellchain-testnet](https://explorer.codeblocklabs.com/worrellchain-testnet) (community-run by [CodeBlockLabs](https://codeblocklabs.com)) · [explorer.utsa.tech/networks/worrell-testnet](https://explorer.utsa.tech/networks/worrell-testnet) (community-run by [UTSA](https://utsa.gitbook.io/services)) · [explorer.vinjan-inc.com/worrell-testnet](https://explorer.vinjan-inc.com/worrell-testnet) (community-run by [Vinjan.Inc](https://vinjan-inc.com)) · [eserckr.xyz/explorer/worrell](https://eserckr.xyz/explorer/worrell) (community-run by [ESERCKR](https://eserckr.xyz)) · [explorer.dnsarz.net/Worrell](https://explorer.dnsarz.net/Worrell/) (community-run by [dnsarz](https://dnsarz.net)) · [explorer.nodestake.org/worrell-testnet](https://explorer.nodestake.org/worrell-testnet) (community-run by [NodeStake](https://nodestake.org)) · [testnet.explorer.stakr.space/worrell](https://testnet.explorer.stakr.space/worrell) (community-run by [STAKR.space](https://stakr.space)) |
| Public REST API | `https://worrell.api.t.anode.team` (community-run by ANODE.TEAM) · `https://worrell-testnet-api.itrocket.net` (community-run by ITRocket) · `https://worrell-testnet-api.nodesync.top` (community-run by NODESYNC) · `https://worrell-testnet-api.bonynode.online` (community-run by BonyNode) · `https://api-worrell.test.onenov.xyz` (community-run by OneNov) · `https://worrellchain-apitest.codeblocklabs.com` (community-run by CodeBlockLabs) · `https://t-worrell.api.utsa.tech` (community-run by UTSA) · `https://api-worrell.dnsarz.net` (community-run by dnsarz) · `https://testnet.worrell.api.srv.stakr.space` (community-run by STAKR.space) |
| Public RPC | `https://worrel-testnet-rpc.oshvank.xyz` (community-run by OshVanK) · `https://worrell-testnet-rpc.itrocket.net` (community-run by ITRocket) · `https://worrell-testnet-rpc.nodesync.top` (community-run by NODESYNC) · `https://worrell-testnet-rpc.bonynode.online` (community-run by BonyNode) · `https://rpc-worrell.test.onenov.xyz` (community-run by OneNov) · `https://worrellchain-rpctest.codeblocklabs.com` (community-run by CodeBlockLabs) · `https://t-worrell.rpc.utsa.tech` (community-run by UTSA) · `https://rpc-worrell.dnsarz.net` (community-run by dnsarz) · `https://lightnode-rpc-worrell.grandvalleys.com` (community-run by Grand Valley) · `https://testnet.worrell.rpc.srv.stakr.space` (community-run by STAKR.space) |
| Public gRPC | `worrell-testnet-grpc.itrocket.net:443` (community-run by ITRocket) · `worrell-testnet-grpc.bonynode.online:443` (community-run by BonyNode) · `testnet.worrell.rpc.srv.stakr.space:28090` (community-run by STAKR.space) |
| BonyNode services | [bonynode.online/services/testnet/worrell](https://bonynode.online/services/testnet/worrell/) (community-run by BonyNode) |
| Sychonix services | [sychonix.com/testnet/worrell](https://sychonix.com/testnet/worrell/) — installation guide, addrbook, genesis, live peers, seeds, RPC, API, snapshots every 6h (community-run by Sychonix) |
| Kynraze services | [kynraze.com/testnet/worrell](https://kynraze.com/testnet/worrell) — RPC, API, gRPC and faucet (community-run by [Kynraze](https://kynraze.com)) |
| Vinjan.Inc services | [vinjan-inc.com/testnet/worrell](https://vinjan-inc.com/testnet/worrell) — guides, API, RPC, snapshots (community-run by [Vinjan.Inc](https://vinjan-inc.com)) |
| NodeStake services | [nodestake.org/networks/worrell](https://nodestake.org/networks/worrell) (community-run by [NodeStake](https://nodestake.org)) · [testnet.explorer.stakr.space/worrell](https://testnet.explorer.stakr.space/worrell) (community-run by [STAKR.space](https://stakr.space)) |
| Community guides | [docs.oshvank.xyz/docs/testnet/Worrel](https://docs.oshvank.xyz/docs/testnet/Worrel) (by OshVanK) · [codeblocklabs.com/docs/cosmos/worrell](https://codeblocklabs.com/docs/cosmos/worrell) (by CodeBlockLabs) · [utsa.gitbook.io/services/testnet/worrell](https://utsa.gitbook.io/services/testnet/worrell) (EN) and [teletype.in/@lesnik13utsa](https://teletype.in/@lesnik13utsa/5gAx-5RmEOD) (RU) (by UTSA) · [github.com/esercakir/worrell-node-deploy](https://github.com/esercakir/worrell-node-deploy) (by ESERCKR) · [explorer.dnsarz.net/Worrell/guides](https://explorer.dnsarz.net/Worrell/guides/) (by dnsarz) · [github.com/walkonwayvs/worrell-state-sync](https://github.com/walkonwayvs/worrell-state-sync) (State Sync procedure, by walkonwayvs) |
| ITRocket services | [itrocket.net/services/testnet/worrell](https://itrocket.net/services/testnet/worrell/) — endpoints (RPC/API/gRPC), snapshots, state sync, seed node, installer, analytics, governance bot (community-run by [ITRocket](https://itrocket.net)) |
| Extra peers | `40128ea31b1cfb5d4b24fc9e32ee0c468586c983@worrell-testnet-peer.itrocket.net:12656` (ITRocket) · `e812f08760b18ed774369e899763735f80179f76@peer-worrell.grandvalleys.com:17656` (Grand Valley) · `56e85e374f58d3aa76f96c07c51f447674e5de19@testnet.worrell.rpc.srv.stakr.space:28656` (STAKR.space) |
| Questions / support | [GitHub Discussions](https://github.com/worrellchain/worrell/discussions) · hello@worrellchain.com |

```bash
# After installing worrelld and running `worrelld init <moniker> --chain-id worrell-testnet-1`:
curl -s https://raw.githubusercontent.com/worrellchain/networks/main/worrell-testnet-1/genesis.json \
  -o ~/.worrell/config/genesis.json
sha256sum ~/.worrell/config/genesis.json   # must match the hash above
sed -i 's|^persistent_peers = .*|persistent_peers = "bb9164c1bd9ed9ff2c0fd9e09b23285698e231de@164.68.98.186:26656"|' ~/.worrell/config/config.toml
sed -i 's|^minimum-gas-prices = .*|minimum-gas-prices = "0.025uworrell"|' ~/.worrell/config/app.toml
worrelld start
```

For the full step-by-step validator guide (hardware, build, sync, create-validator,
monitoring), see [docs/RUNNING-A-NODE.md](https://github.com/worrellchain/worrell/blob/main/docs/RUNNING-A-NODE.md)
in the code repository.

## Contents of each network

- **`chain.json`** — Chain Registry metadata (chain_id, peers, fees, version, genesis URL).
- **`assetlist.json`** — token definition (WORRELL / uworrell, 6 decimals).
- **`genesis.json`** — the official genesis file; every node must use this exact file.
- **`config.yml`** — Ignite configuration (accounts, validator, module parameters, faucet).
- **`setup-genesis.sh`** — rebuilds the genesis from scratch with `worrelld` + `jq` (used to *create* the network, not to join it).
- **`setup-multisig.sh`** — creates the signer keys, auxiliary keys, and multisig accounts (treasury 3/3; airdrop/incentives/reserve 2/4).

> Note: to *join* the network, download the published `genesis.json` above — do **not** run
> `setup-genesis.sh`, which would generate a different (incompatible) network.
