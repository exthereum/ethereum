use Mix.Config

config :ex_wire,
  network_adapter: ExWire.Adapter.UDP,
  sync: true,
  commitment_count: 2 # Number of peer advertisements before we trust a block
