# Exthereum

Exthereum is an Elixir client for the Ethereum blockchain.

## Installation

First, add Ethereum to your `mix.exs` dependencies:

```elixir
def deps do
  [{:ethereum, "~> 0.2.0"}]
end
```

Then, update your dependencies:

```sh-session
$ mix deps.get
```

## Usage

Currently, Exthereum is a set of libraries. In time, this section will include how to run and sync the chain.

## Architecture

This app is devided into different sub-apps, described here:

* `apps/abi` - The ABI encoding library (for interaction with Solidity)
* `apps/blockchain` - Validates and connects blocks into a chain
* `apps/evm` - Runs the Ethereum VM (EVM1)
* `apps/ex_rlp` - Recrusive-length encoding format used in Ethereum
* `apps/ex_wire` - The DevP2P protocol
* `apps/exth_crypto` - Wrappers for ethereum-specific cryptographic protocols
* `apps/hex_prefix` - Encoding format used in Ethereum
* `apps/merkle_patricia_tree` - A tree to canonically store data returning a state root

## License

Exthereum is released under the MIT license.

## Contributing

Create a pull request or come visit us in [Gitter](https://gitter.im/exthereum/exthereum).