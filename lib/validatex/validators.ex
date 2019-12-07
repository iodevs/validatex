defmodule Validatex.Validators do
  @moduledoc """
  This module provides a few functions for validating data.
  """

  @type raw() :: String.t()
  @type error_msg() :: String.t()

  defguard raw?(str) when is_binary(str)
  defguard error_msg?(msg) when is_binary(msg)

  @spec not_empty?(raw(), error_msg()) :: Result.t(error_msg(), raw())
  def not_empty?("", msg) when is_binary(msg) do
    {:error, msg}
  end

  def not_empty?(value, _) when is_binary(value) do
    {:ok, value}
  end

  @spec range(raw(), integer(), integer(), error_msg()) :: Result.t(error_msg(), raw())
  def range(value, min, max, msg)
      when is_binary(value) and is_integer(min) and is_integer(max) and is_binary(msg) do
    if String.length(value) in min..max do
      {:ok, value}
    else
      {:error, msg}
    end
  end

  @spec integer(raw(), 2..36, error_msg()) :: Result.t(error_msg(), integer())
  def integer(value, base \\ 10, msg) when raw?(value) and is_integer(base) and error_msg?(msg) do
    case Integer.parse(value, base) do
      {i, ""} ->
        {:ok, i}

      _ ->
        {:error, msg}
    end
  end

  @spec float(raw(), error_msg()) :: Result.t(error_msg(), float())
  def float(value, msg) when raw?(value) and error_msg?(msg) do
    case Float.parse(value) do
      {f, ""} ->
        {:ok, f}

      _ ->
        {:error, msg}
    end
  end

  @spec true?(boolean(), error_msg()) :: Result.t(error_msg(), true)
  def true?(true, _msg), do: {:ok, true}
  def true?(false, msg), do: {:error, msg}

  @spec in_list(a, [a], error_msg()) :: Result.t(error_msg(), a) when a: var
  def in_list(value, list, msg) when is_list(list) and error_msg?(msg) do
    if value in list do
      {:ok, value}
    else
      {:error, msg}
    end
  end

  @spec format(raw(), Regex.t(), error_msg()) :: Result.t(error_msg(), raw())
  def format(value, %Regex{} = regex, msg) when raw?(value) and error_msg?(msg) do
    if value =~ regex do
      {:ok, value}
    else
      {:error, msg}
    end
  end
end
