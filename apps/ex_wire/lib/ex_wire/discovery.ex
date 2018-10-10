defmodule ExWire.Discovery do
  @moduledoc """
  Discovery is responsible for discovering a number of neighbors
  using the RLPx Discovery Protocol.
  """

  use GenServer

  require Logger

  alias ExWire.Struct.Neighbour

  @min_neighbours 50

  @doc """
  Starts a Discovery server.
  """
  def start_link(bootnodes) do
    GenServer.start_link(__MODULE__, bootnodes, name: __MODULE__)
  end

  @doc """
  Once we start a Discovery server with bootnodes, we'll connect
  and ask them for neighbours.
  """
  def init(nodes) do
    # Configure how we describe ourselves
    local_endpoint =
      if ExWire.Config.use_nat() do
        # Use a NAT for inbound ports
        {:ok, context} = :nat_upnp.discover()

        # TODO: Should we remove existing mapping?
        # :nat_upnp.delete_port_mapping(context, :udp, ExWire.Config.listen_port())

        {_, _, ip_address_binary} = context
        {:ok, ip_address} = :inet.parse_address(ip_address_binary)

        :ok =
          :nat_upnp.add_port_mapping(
            context,
            :udp,
            ExWire.Config.listen_port(),
            ExWire.Config.listen_port(),
            'discovery mapping',
            0
          )

        %ExWire.Struct.Endpoint{
          ip: ip_address,
          udp_port: ExWire.Config.listen_port(),
          tcp_port: ExWire.Config.listen_port()
        }
      else
        # Use defaults
        %ExWire.Struct.Endpoint{
          ip: ExWire.Config.local_ip(),
          udp_port: ExWire.Config.listen_port(),
          tcp_port: ExWire.Config.listen_port()
        }
      end

    :timer.sleep(1000)

    neighbours =
      for node <- nodes do
        {:ok, neighbour} = ExWire.Struct.Neighbour.from_uri(node)

        ping_neighbour(neighbour, local_endpoint)

        neighbour
      end

    {:ok,
     %{
       neighbours: neighbours,
       local_endpoint: local_endpoint
     }}
  end

  def handle_cast({:ping, node_id}, state) do
    Logger.debug(fn ->
      "[Discovery] Received ping to #{node_id |> ExthCrypto.Math.bin_to_hex()}"
    end)

    # For now, do nothing.

    {:noreply, state}
  end

  def handle_cast({:pong, node_id}, state = %{neighbours: neighbours}) do
    Logger.debug(fn ->
      "[Discovery] Received pong from #{node_id |> ExthCrypto.Math.bin_to_hex()}"
    end)

    # If we get a pong and we like it, we should connect via TCP.
    case Enum.find(neighbours, fn neighbour -> neighbour.node == node_id end) do
      nil ->
        Logger.debug("[Discovery] Ignoring pong, unknown node..")

      neighbour ->
        Logger.debug("[Discovery] Got pong from known peer, connecting via TCP.")
        find_neighbours(neighbour)
        ExWire.PeerSupervisor.connect(neighbour)
    end

    {:noreply, state}
  end

  def handle_cast(
        {:add_neighbours, add_neighbours},
        state = %{neighbours: neighbours, local_endpoint: local_endpoint}
      ) do
    # If these are new nodes, we should ping them to see round-trip
    # time. If we like the neighbour, we can try and establish a
    # RLPx connection.
    known_nodes = for neighbour <- neighbours, do: neighbour.node

    new_neighbours =
      Enum.filter(add_neighbours.nodes, fn neighbour ->
        neighbour.node != ExWire.Config.node_id() and
          not Enum.member?(known_nodes, neighbour.node)
      end)

    Logger.debug(fn ->
      "[Discovery] Hi-dilly-ho received #{Enum.count(add_neighbours.nodes)} neighboureenos, #{
        Enum.count(new_neighbours)
      } newerific"
    end)

    # For each new neighbour, send a ping
    for neighbour <- new_neighbours do
      ping_neighbour(neighbour, local_endpoint)

      if Enum.count(neighbours) < @min_neighbours do
        find_neighbours(neighbour)
      end
    end

    total_neighbours = neighbours ++ new_neighbours

    Logger.debug(fn -> "[Discovery] Neighbour Count: #{Enum.count(total_neighbours)}" end)

    {:noreply, Map.put(state, :neighbours, total_neighbours)}
  end

  def handle_call({:get_neighbours, _target}, _from, state = %{neighbours: neighbours}) do
    {:reply, neighbours, state}
  end

  @doc """
  Informs us that we decided to ping a node. We are interested
  in this so that we can track the round-trip time.
  """
  @spec ping(pid(), ExWire.node_id()) :: :ok
  def ping(pid, node_id) do
    GenServer.cast(pid, {:ping, node_id})
  end

  @doc """
  Informs us that a node has responded to a ping. This is important since
  we may decide to ask this node for neighbours.
  """
  @spec pong(pid(), ExWire.node_id()) :: :ok
  def pong(pid, node_id) do
    GenServer.cast(pid, {:pong, node_id})
  end

  @doc """
  Informs us that we have been told of the existence
  of these neighbours. We will ping new neighbours before
  adding them to our list.
  """
  @spec add_neighbours(pid(), [Neighbour.t()]) :: :ok
  def add_neighbours(pid, neighbours) do
    GenServer.cast(pid, {:add_neighbours, neighbours})
  end

  @doc """
  Asks for neighbours. If target is given, we'll try to find
  neighbours close to that target.
  """
  @spec get_neighbours(pid()) :: [Neighbour.t()]
  def get_neighbours(pid, target \\ nil) do
    GenServer.call(pid, {:get_neighbours, target})
  end

  defp ping_neighbour(neighbour, local_endpoint) do
    Logger.debug(fn ->
      "[Discovery] Initiating ping to #{inspect(neighbour, limit: :infinity)}, #{
        inspect(local_endpoint, limit: :infinity)
      }"
    end)

    # Send a ping to each node
    ping = %ExWire.Message.Ping{
      version: 1,
      from: local_endpoint,
      to: neighbour.endpoint,
      timestamp: ExWire.Util.Timestamp.soon()
    }

    ExWire.Network.send(ping, ExWire.Adapter.UDP, neighbour.endpoint)
  end

  defp find_neighbours(neighbour) do
    # Logger.debug("[Discovery] Initiating find neighbours to #{inspect neighbour, limit: :infinity}")

    # Ask node for neighbours
    find_neighbours = %ExWire.Message.FindNeighbours{
      # random target address
      target: ExthCrypto.Math.nonce(64),
      timestamp: ExWire.Util.Timestamp.soon()
    }

    ExWire.Network.send(find_neighbours, ExWire.Adapter.UDP, neighbour.endpoint)
  end
end
