defmodule Validatex.Validators do
  @moduledoc """
  This module provides a few functions for validating data.

  All functions return [Result](https://hexdocs.pm/result/api-reference.html).
  It means, if an input value is correct, function returns a tuple `{:ok, val}`.
  If not then `{:error, "msg"}`.

  Usage:

  Let say that you have a few input forms on your page, for instance: name,
  surname, password etc. Now you want to validate that the filled data are correct
  for each field. So you create somewhere inside your project a module `Validators`
  which will be containing any of functions like bellow.

  Note:

  Each function has a default error message. This message can be rewritten
  according to your needs.
  """

  @type raw() :: String.t()
  @type error_msg() :: String.t()

  @doc """
  Guard for verifying if `raw` is a string.
  """
  defguard raw?(str) when is_binary(str)

  @doc """
  Guard for verifying if error `msg` is a string.
  """
  defguard error_msg?(msg) when is_binary(msg)

  @doc """
  Validates if the input value is empty or not.

  ## Example:
      # Validators.ex

      @spec name(String.t()) :: Result.t(String.t(), String.t())
      def name(value) do
        Validators.not_empty?(value, "Name is required!")
      end
  """
  @spec is_not_empty?(raw(), error_msg()) :: Result.t(error_msg(), raw())
  def is_not_empty?(value, msg \\ "The value must not be an empty!")

  def is_not_empty?("", msg) when is_binary(msg) do
    Result.error(msg)
  end

  def is_not_empty?(value, _) when is_binary(value) do
    Result.ok(value)
  end

  @doc """
  Validates if the input value is integer.

  ## Example:
      @spec score(String.t()) :: Result.t(String.t(), integer())
      def score(value) do
        Validators.is_integer?(value, "The score has to be integer!")
      end
  """
  @spec is_integer?(raw(), 2..36, error_msg()) :: Result.t(error_msg(), integer())
  def is_integer?(value, base \\ 10, msg \\ "The value has to be an integer!")
      when raw?(value) and is_integer(base) and error_msg?(msg) do
    value |> Integer.parse() |> case_do(msg)
  end

  @doc """
  Validates if the input value is float.

  ## Example:
      @spec temperature(String.t()) :: Result.t(String.t(), float())
      def temperature(value) do
        Validators.is_float?(value, "The temperature has to be float!")
      end
  """
  @spec is_float?(raw(), error_msg()) :: Result.t(error_msg(), float())
  def is_float?(value, msg \\ "The value has to be a float!")
      when raw?(value) and error_msg?(msg) do
    value |> Float.parse() |> case_do(msg)
  end

  @doc """
  Validates if the input value is less than required value.

  ## Example:
      @spec count(String.t()) :: Result.t(String.t(), number())
      def count(value) do
        Validators.is_less_than?(value, 10, "The value has to be less than 10!")
      end
  """
  @spec is_less_than?(raw(), number(), error_msg()) :: Result.t(error_msg(), number())
  def is_less_than?(value, req_val, msg \\ "The value has to be less than required value!")
      when raw?(value) and is_number(req_val) and error_msg?(msg) do
    validate(value, req_val, msg, &less_than/3)
  end

  @doc """
  Validates if the input value is less or equal to required value.

  ## Example:
      @spec total_count(String.t()) :: Result.t(String.t(), number())
      def total_count(value) do
        Validators.is_at_most?(value, 10, "The value has to be less or equal to 10!")
      end
  """
  @spec is_at_most?(raw(), number(), error_msg()) :: Result.t(error_msg(), number())
  def is_at_most?(value, req_val, msg \\ "The value has to be less or equal to required value!")
      when raw?(value) and is_number(req_val) and error_msg?(msg) do
    validate(value, req_val, msg, &at_most/3)
  end

  @doc """
  Validates if the input value is greater than required value.
  """
  @spec is_greater_than?(raw(), number(), error_msg()) :: Result.t(error_msg(), number())
  def is_greater_than?(value, req_val, msg \\ "The value has to be greater than required value!")
      when raw?(value) and is_number(req_val) and error_msg?(msg) do
    validate(value, req_val, msg, &greater_than/3)
  end

  @doc """
  Validates if the input value is greater or equal to required value.
  """
  @spec is_at_least?(raw(), number(), error_msg()) :: Result.t(error_msg(), number())
  def is_at_least?(
        value,
        req_val,
        msg \\ "The value has to be greater or equal to required value!"
      )
      when raw?(value) and is_number(req_val) and error_msg?(msg) do
    validate(value, req_val, msg, &at_least/3)
  end

  @doc """
  Validates if the input value is between two numbers (integer or float)
  (mathematically speaking it's closed interval).

  ## Example:
      @spec password(String.t()) :: Result.t(String.t(), String.t())
      def password(pass) do
        min = 6
        max = 12

        [
          Validators.not_empty?(value, "Passsword is required!"),
          pass
          |> String.length()
          |> Kernel.to_string()
          |> Validators.is_in_range?(min, max,
            "Password has to be at most #\{min\} and at least #\{max\} lenght!"
            )
        ]
        |> Result.product()
        |> Result.map(&hd/1)
      end
  """
  @spec is_in_range?(raw(), number(), number(), error_msg()) ::
          Result.t(error_msg(), number())
  def is_in_range?(value, min, max, msg)
      when raw?(value) and is_number(min) and is_number(max) and is_binary(msg) do
    validate(value, [min, max], msg, &in_range/3)
  end

  @doc """
  Validates if the input value is equal to required value.

  ## Example:
      @spec captcha(String.t()) :: Result.t(String.t(), number())
      def captcha(value) do
        Validators.is_equal_to?(value, 10, "The summation has to be equal to 10!")
      end
  """
  @spec is_equal_to?(raw(), number() | String.t(), error_msg()) ::
          Result.t(error_msg(), number() | String.t())
  def is_equal_to?(value, req_val, msg \\ "The value has to be equal to required value!")

  def is_equal_to?(value, req_val, msg)
      when raw?(value) and is_number(req_val) and error_msg?(msg) do
    validate(value, req_val, msg, &equal_to/3)
  end

  def is_equal_to?(value, req_val, msg)
      when raw?(value) and is_binary(req_val) and error_msg?(msg) do
    if value == req_val do
      Result.ok(value)
    else
      Result.error(msg)
    end
  end

  @doc """
  Validates if the input value is true or false.
  """
  @spec is_true?(boolean(), error_msg()) :: Result.t(error_msg(), true)
  def is_true?(true, _msg), do: {:ok, true}
  def is_true?(false, msg), do: {:error, msg}

  @doc """
  Validates if the input value is inside required list.
  """
  @spec is_in_list?(a, [a], error_msg()) :: Result.t(error_msg(), a) when a: var
  def is_in_list?(value, list, msg) when is_list(list) and error_msg?(msg) do
    if value in list do
      Result.ok(value)
    else
      Result.error(msg)
    end
  end

  @doc """
  In case of validating complex input data you can use regex.

  ## Example:
      @spec date(String.t()) :: Result.t(String.t(), Date.t())
      def date(value) do
        Validators.format(
        value,
        ~r/^\d{1,2}\.\d{1,2}\.(\d{4})?$/,
        "Correct date is, for example in format 11.12.1918 or 03.08.2008."
      )
      end

      @spec email(String.t()) :: Result.t(String.t(), String.t())
      def email(value) do
        Validators.format(
          value,
          ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/,
          "It's required valid email!"
        )
      end
  """
  @spec format(raw(), Regex.t(), error_msg()) :: Result.t(error_msg(), raw())
  def format(value, %Regex{} = regex, msg) when raw?(value) and error_msg?(msg) do
    if value =~ regex do
      {:ok, value}
    else
      {:error, msg}
    end
  end

  # Private

  defp validate(value, req_val, msg, fun) when is_function(fun, 3) do
    value
    |> is_integer?()
    |> Result.r_or(is_float?(value))
    |> not_integer_either_float()
    |> Result.map(&fun.(&1, req_val, msg))
    |> Result.resolve()
  end

  defp case_do(tpl, msg) do
    case tpl do
      {val, ""} ->
        Result.ok(val)

      _ ->
        Result.error(msg)
    end
  end

  defp not_integer_either_float({:error, errs_list}) when length(errs_list) == 2 do
    Result.error("The value has to be integer or float!")
  end

  defp not_integer_either_float(is_ok), do: is_ok

  defp less_than([num | _tl], limit, _msg) when num < limit do
    Result.ok(num)
  end

  defp less_than(_num, _limit, msg) do
    Result.error(msg)
  end

  defp at_most([num | _tl], limit, _msg) when num <= limit do
    Result.ok(num)
  end

  defp at_most(_num, _limit, msg) do
    Result.error(msg)
  end

  defp greater_than([num | _tl], limit, _msg) when limit < num do
    Result.ok(num)
  end

  defp greater_than(_num, _limit, msg) do
    Result.error(msg)
  end

  defp at_least([num | _tl], limit, _msg) when limit <= num do
    Result.ok(num)
  end

  defp at_least(_num, _limit, msg) do
    Result.error(msg)
  end

  defp in_range([num | _tl], [min, max], _msg) when min <= num and num <= max do
    Result.ok(num)
  end

  defp in_range(_num, _min_max, msg) do
    Result.error(msg)
  end

  defp equal_to([num | _tl], limit, _msg) when num == limit do
    Result.ok(num)
  end

  defp equal_to(_num, _limit, msg) do
    Result.error(msg)
  end
end
