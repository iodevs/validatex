defmodule ValidatorsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use PropCheck

  alias Validatex.Validators

  @error_msg "ERROR"

  # Properties

  property "should verify if input value is not empty" do
    forall value <- binary() do
      value |> Validators.not_empty(@error_msg) |> check_result(value, @error_msg)
    end
  end

  property "should verify if input value is an integer" do
    forall value <- generate_data() do
      check_fn_with_value(&Validators.integer/2, value)
    end
  end

  property "should verify if input value is a float" do
    forall value <- generate_data() do
      check_fn_with_value(&Validators.float/2, value)
    end
  end

  property "should verify if input value is less than required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn_with_value_and_limit(&Validators.less_than/3, value, limit)
    end
  end

  property "should verify if input value is less or equal to required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn_with_value_and_limit(&Validators.at_most/3, value, limit)
    end
  end

  property "should verify if input value is greater than required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn_with_value_and_limit(&Validators.greater_than/3, value, limit)
    end
  end

  property "should verify if input value is greater or equal to required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn_with_value_and_limit(&Validators.at_least/3, value, limit)
    end
  end

  property "should verify if input value is is between two numbers" do
    forall {value, {n1, n2}} <-
             {generate_data(), oneof([{integer(), integer()}, {float(), float()}])} do
      value
      |> Kernel.to_string()
      |> Validators.in_range(min(n1, n2), max(n1, n2), @error_msg)
      |> check_result(value, @error_msg)
    end
  end

  property "should verify if input value is equal to required value" do
    forall {value, limit} <- {generate_data(), number()} do
      check_fn_with_value_and_limit(&Validators.equal?/3, value, Enum.random([value, limit]))
    end
  end

  property "should verify if input value is true or false" do
    forall value <- boolean() do
      value |> Validators.true?(@error_msg) |> check_result(value, @error_msg)
    end
  end

  property "should verify if input value is inside required list" do
    forall {value, lst} <- {number(), list(number())} do
      value
      |> Validators.in_list(lst, @error_msg)
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
    only_string =
      such_that(
        v <- binary(),
        when: not Regex.match?(~r/^[+-]?([0-9]*[.])?[0-9]+$/, v)
      )

    oneof([
      number(),
      only_string
    ])
  end

  # Private

  defp check_fn_with_value(fun, value) do
    value
    |> Kernel.to_string()
    |> fun.(@error_msg)
    |> check_result(value, @error_msg)
  end

  defp check_fn_with_value_and_limit(fun, value, limit) do
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
        msg in [
          expected_msg,
          "The value has to be an integer!",
          "The value has to be a float!",
          "The value must not be an empty!"
        ]
    end
  end
end
