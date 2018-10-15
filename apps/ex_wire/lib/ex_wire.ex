defmodule ExWire do
  @moduledoc """
  Main application for ExWire. We will begin listening on a port
  when this application is started.
  """

  @default_network_adapter Application.get_env(:ex_wire, :network_adapter)

  @type node_id :: binary()

  use Application
  alias ExWire.Config
  alias ExWire.Discovery
  alias ExWire.Sync
  alias ExWire.Network
  alias MerklePatriciaTree.Test

  def start(_type, args) do
    import Supervisor.Spec

    network_adapter = Keyword.get(args, :network_adapter, @default_network_adapter)
    port = Keyword.get(args, :port, Config.listen_port())
    name = Keyword.get(args, :name, ExWire)

    sync_children =
      case Config.sync() do
        true ->
          # TODO: Replace with level db
          db = Test.random_ets_db()

          [
            worker(Discovery, [Config.bootnodes()]),
            worker(PeerSupervisor, [:ok]),
            worker(Sync, [db])
          ]

        _ ->
          []
      end

    discovery =
      case Config.sync() do
        true -> Discovery
        _ -> nil
      end

    children =
      [
        worker(network_adapter, [{Network, [discovery]}, port],
          name: Network,
          restart: :permanent
        )
      ] ++ sync_children

    opts = [strategy: :one_for_one, name: name]
    Supervisor.start_link(children, opts)
  end
end
