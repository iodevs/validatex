defmodule Validatex.MapExtra do
  @moduledoc """
  A map functions.
  """

  import Validatex.Validation, only: [key?: 1]

  @doc """
  Gets the value for a specific `key` in `map`. If `key` isn't present in `map`,
  the `RuntimeError` will be raised.

      iex> Validatex.MapExtra.get!(%{"name" => "Foo"}, "name")
      "Foo"
      iex> Validatex.MapExtra.get!(%{"name" => "Foo"}, "surname")
      ** (RuntimeError) Key 'surname' not found in '%{"name" => "Foo"}'.

  """
  @spec get!(map(), atom() | String.t()) :: any() | no_return()
  def get!(map, key) when is_map(map) and key?(key) do
    Map.get(map, key) || raise "Key '#{key}' not found in '#{inspect(map)}'."
  end
end
