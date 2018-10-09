use Mix.Config

config :ex_wire,
  network_adapter: ExWire.Adapter.UDP,
  sync: true,
  use_nat: true,
  local_ip: {127, 0, 0, 1},
  # Number of peer advertisements before we trust a block
  commitment_count: 2
