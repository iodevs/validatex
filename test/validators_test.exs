defmodule ValidatorsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use PropCheck

  doctest Validatex.Validators
  alias Validatex.Validators

  @error_msg "ERROR"

  # Properties

  property "should verify if input value is not empty" do
    forall value <- binary() do
      value |> Validators.is_not_empty?(@error_msg) |> check_result(value, @error_msg)
    end
  end

  property "should verify if input value is an integer" do
    forall value <- generate_data() do
      check_fn(&Validators.is_integer?/2, value)
    end
  end

  property "should verify if input value is a float" do
    forall value <- generate_data() do
      check_fn(&Validators.is_float?/2, value)
    end
  end

  property "should verify if input value is less than required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn(&Validators.is_less_than?/3, value, limit)
    end
  end

  property "should verify if input value is less or equal to required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn(&Validators.is_at_most?/3, value, limit)
    end
  end

  property "should verify if input value is greater than required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn(&Validators.is_greater_than?/3, value, limit)
    end
  end

  property "should verify if input value is greater or equal to required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn(&Validators.is_at_least?/3, value, limit)
    end
  end

  property "should verify if input value is is between two numbers" do
    forall {value, n1, n2} <- {generate_data(), number(), number()} do
      check_fn(&Validators.is_in_range?/4, value, [min(n1, n2), max(n1, n2)])
    end
  end

  property "should verify if input value is equal to required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn(&Validators.is_equal_to?/3, value, Enum.random([value, limit]))
    end
  end

  property "should verify if input value is true or false" do
    forall value <- boolean() do
      value |> Validators.is_true?(@error_msg) |> check_result(value, @error_msg)
    end
  end

  property "should verify if input value is inside required list" do
    forall {value, lst} <- {number(), list(number())} do
      value
      |> Validators.is_in_list?(lst, @error_msg)
      |> check_result(value, @error_msg)
    end
  end

  property "should verify if the input value fits the given regex" do
    forall value <- integer() do
      value
      |> Kernel.to_string()
      |> Validators.format(~r/^[[:alnum:]]+$/, @error_msg)
      |> check_result("#{value}", @error_msg)
    end
  end

  # Generator

  def generate_data() do
    binary =
      let str <- binary() do
        str <> "x"
      end

    oneof([
      number(),
      binary,
      ""
    ])
  end

  # Private

  defp check_fn(fun, value) do
    value
    |> Kernel.to_string()
    |> fun.(@error_msg)
    |> check_result(value, @error_msg)
  end

  defp check_fn(fun, value, [min, max]) do
    value
    |> Kernel.to_string()
    |> fun.(min, max, @error_msg)
    |> check_result(value, @error_msg)
  end

  defp check_fn(fun, value, limit) do
    value
    |> Kernel.to_string()
    |> fun.(limit, @error_msg)
    |> check_result(value, @error_msg)
  end

  defp check_result(rv, expected, expected_msg) do
    case rv do
      {:ok, val} ->
        val == expected

      {:error, msg} ->
        msg == expected_msg or msg == "The value has to be integer or float!"
    end
  end
end
