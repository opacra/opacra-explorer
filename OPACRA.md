# Opacra block explorer

This is the [Onion Monero Blockchain Explorer](https://github.com/moneroexamples/onion-monero-blockchain-explorer)
(BSD-3-Clause, by moneroexamples) adapted for [Opacra](https://opacra.org). It is based on
upstream commit 5d9e37c, the last one that builds against Monero v0.18.5.1, which Opacra forks.

## What changed

- Opacra names, ports (mainnet 29961, testnet 29971, stagenet 29981 daemon RPC) and wallet file magics.
- Development fund: every Opacra coinbase has a second transaction public key, the fund's per-height
  key R_f, and pays 5% of the block's new coins to the fund as its last output.
  - The explorer shows the transaction's own (first) public key, and the output decoder (HTML and
    `/api/outputs`) also tries R_f on coinbase transactions, so the fund's output is found.
  - The home page shows the fund's address and public view key for the network it runs on.
  - Every coinbase transaction page has a *Development fund* tab that decodes the block's outputs
    with the fund's published keys in one click.
- Restyled with the opacra.org colours (light and dark), system fonts only, still no JavaScript.
- Builds without miniupnpc.

## Build

Build Opacra first (`build/portable`), then:

```
mkdir build && cd build
cmake -DMONERO_DIR=/path/to/opacra -DMONERO_BUILD_DIR=/path/to/opacra/build/portable -DCMAKE_BUILD_TYPE=Release ..
make -j2
./xmrblocks --testnet -b ~/.opacra/testnet/lmdb -d 127.0.0.1:29971
```

`xmrblocks` reads its pages from `./templates`, so run it from the build folder (or the install folder).

## Deploy next to a seed node

`contrib/opacra/package.sh` makes `opacra-explorer-<version>-linux-x64.tar.gz`. On a server that
already runs the Opacra testnet seed node, unpack it and run `sudo ./explorer-setup.sh`. It installs
a systemd service on 127.0.0.1:8081, nginx with rate limiting and no access log (the decoder puts
addresses and view keys in URLs), and an HTTPS certificate once `explorer.opacra.org` points at the
server.
