defmodule Validatex.MapExtra do
  @moduledoc """
  A map functions.
  """

  import Validatex.Validation, only: [key?: 1]

  @spec get!(map(), atom() | String.t()) :: any() | no_return()
  def get!(map, key) when is_map(map) and key?(key) do
    Map.get(map, key) || raise "Key '#{key}' not found in '#{inspect(map)}'."
  end
end
