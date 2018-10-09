defmodule ExWire.Struct.Endpoint do
  @moduledoc """
  Struct to represent an endpoint in ExWire.
  """

  defstruct ip: nil,
            udp_port: nil,
            tcp_port: nil

  @type ip :: :inet.ip_address()
  @type ip_port :: non_neg_integer()

  @type t :: %__MODULE__{
          ip: ip,
          udp_port: ip_port | nil,
          tcp_port: ip_port | nil
        }

  @doc """
  Returns a struct given an `ip` in binary form, plus an
  `udp_port` or `tcp_port`.

  ## Examples

      iex> ExWire.Struct.Endpoint.decode([<<1,2,3,4>>, <<>>, <<5>>])
      %ExWire.Struct.Endpoint{
        ip: {1, 2, 3, 4},
        udp_port: nil,
        tcp_port: 5,
      }
  """
  @spec decode(ExRLP.t()) :: t
  def decode([ip, udp_port, tcp_port]) do
    %__MODULE__{
      ip: decode_ip(ip),
      udp_port: decode_port(udp_port),
      tcp_port: decode_port(tcp_port)
    }
  end

  @doc """
  Given an IPv4 or IPv6 address in binary form,
  returns the address in list form.

  ## Examples

      iex> ExWire.Struct.Endpoint.decode_ip(<<1,2,3,4>>)
      {1, 2, 3, 4}

      iex> ExWire.Struct.Endpoint.decode_ip(<<1::128>>)
      {0, 0, 0, 0, 0, 0, 0, 1}

      iex> ExWire.Struct.Endpoint.decode_ip(<<0xff, 0xff, 0xff, 0xff>>)
      {255, 255, 255, 255}

      iex> ExWire.Struct.Endpoint.decode_ip(<<127, 0, 0, 1>>)
      {127, 0, 0, 1}
  """
  @spec decode_ip(binary()) :: ip
  def decode_ip(data) do
    case data do
      <<>> ->
        {}

      <<p_0, p_1, p_2, p_3>> ->
        {p_0, p_1, p_2, p_3}

      <<p_0::16, p_1::16, p_2::16, p_3::16, p_4::16, p_5::16, p_6::16, p_7::16>> ->
        {p_0, p_1, p_2, p_3, p_4, p_5, p_6, p_7}
    end
  end

  @doc """
  Returns a port given a binary version of the port
  as input. Note: we return `nil` for an empty or zero binary.

  ## Examples

      iex> ExWire.Struct.Endpoint.decode_port(<<>>)
      nil

      iex> ExWire.Struct.Endpoint.decode_port(<<0>>)
      nil

      iex> ExWire.Struct.Endpoint.decode_port(<<0, 0>>)
      nil

      iex> ExWire.Struct.Endpoint.decode_port(<<1>>)
      1

      iex> ExWire.Struct.Endpoint.decode_port(<<1, 0>>)
      256
  """
  def decode_port(data) do
    case :binary.decode_unsigned(data) do
      0 -> nil
      port -> port
    end
  end

  @doc """
  Versus `decode/3`, and given a module with an ip, a tcp_port and
  a udp_port, returns a tuple of encoded values.

  ## Examples

      iex> ExWire.Struct.Endpoint.encode(%ExWire.Struct.Endpoint{ip: {1, 2, 3, 4}, udp_port: nil, tcp_port: 5})
      [<<1, 2, 3, 4>>, <<>>, <<0, 5>>]
  """
  @spec encode(t) :: ExRLP.t()
  def encode(%__MODULE__{ip: ip, tcp_port: tcp_port, udp_port: udp_port}) do
    [
      encode_ip(ip),
      encode_port(udp_port),
      encode_port(tcp_port)
    ]
  end

  @doc """
  Given an ip address that's an encoded as a list,
  returns that address encoded as a binary.

  ## Examples

      iex> ExWire.Struct.Endpoint.encode_ip({1, 2, 3, 4})
      <<1, 2, 3, 4>>

      iex> ExWire.Struct.Endpoint.encode_ip({0, 0, 0, 0, 0, 0, 0, 1})
      <<1::128>>

      iex> ExWire.Struct.Endpoint.encode_ip({0xffff, 0x0000, 0xff00, 0x0000, 0x2233, 0x00ff, 0x1122, 0x3344})
      <<255, 255, 0, 0, 255, 0, 0, 0, 34, 51, 0, 255, 17, 34, 51, 68>>
  """
  @spec encode_ip(ip) :: binary()
  def encode_ip(ip) do
    case ip do
      {p_0, p_1, p_2, p_3} ->
        <<p_0, p_1, p_2, p_3>>

      {p_0, p_1, p_2, p_3, p_4, p_5, p_6, p_7} ->
        encode_word(p_0) <>
          encode_word(p_1) <>
          encode_word(p_2) <>
          encode_word(p_3) <>
          encode_word(p_4) <> encode_word(p_5) <> encode_word(p_6) <> encode_word(p_7)
    end
  end

  @doc """
  Given a port, returns that port encoded in binary.

  ## Examples

      iex> ExWire.Struct.Endpoint.encode_port(256)
      <<1, 0>>

      iex> ExWire.Struct.Endpoint.encode_port(nil)
      <<>>

      iex> ExWire.Struct.Endpoint.encode_port(0)
      <<0, 0>>
  """
  @spec encode_port(ip_port | nil) :: binary()
  def encode_port(port) do
    case port do
      nil -> <<>>
      _ -> port |> :binary.encode_unsigned() |> ExthCrypto.Math.pad(2)
    end
  end

  @doc """
  Returns a string representing the IP address.

  ## Examples

      iex> ExWire.Struct.Endpoint.ip_to_string({1, 2, 3, 4})
      "1.2.3.4"

      iex> ExWire.Struct.Endpoint.ip_to_string({0, 0, 0, 0, 0, 0, 0, 1})
      "::1"

      iex> ExWire.Struct.Endpoint.ip_to_string({0xffff, 0xffff, 0xff00, 0xff00, 0x00ff, 0x00ff, 0x1122, 0x1122})
      "ffff:ffff:ff00:ff00:ff:ff:1122:1122"
  """
  def ip_to_string(ip) do
    :inet_parse.ntoa(ip) |> to_string
  end

  defp encode_word(word) do
    case word |> :binary.encode_unsigned() do
      <<single_byte::binary-size(1)>> -> <<0>> <> single_byte
      <<double_byte::binary-size(2)>> -> double_byte
    end
  end
end
