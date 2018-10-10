defmodule Exth do
  @moduledoc """
  General helper functions, like for inspection.
  """
  require Logger

  @spec view(any(), String.t() | nil) :: any()
  def view(variable, prefix \\ nil) do
    args = if prefix, do: [prefix, variable], else: variable

    _ = Logger.debug(fn -> "#{inspect(args)}" end)

    variable
  end
end
