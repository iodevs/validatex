defmodule Validatex.Validation do
  @moduledoc """
  This module helps with validation of input forms.
  """

  @type validator(a, b) :: (a -> Result.t(String.t(), b))

  @type not_validated() :: :not_validated
  @type valid(a) :: {:valid, a}
  @type invalid() :: {:invalid, String.t()}

  @type validity(a) :: not_validated() | valid(a) | invalid()
  @type field(raw, a) :: {:field, raw, validity(a)}

  @type on_submit() :: :on_submit
  @type on_blur() :: :on_blur
  @type on_related_change() :: :on_related_change
  @type on_change(val) :: {:on_change, val}
  @type event(raw) :: on_submit() | on_blur() | on_related_change() | on_change(raw)

  defguard validator?(f) when is_function(f, 1)

  @spec raw_value(field(raw, any())) :: raw when raw: var
  def raw_value({:field, raw, _}) do
    raw
  end

  @spec validity(field(any(), a)) :: validity(a) when a: var
  def validity({:field, _, validity}) do
    validity
  end

  @spec field(raw) :: {:field, raw, :not_validated} when raw: var
  def field(raw) do
    {:field, raw, :not_validated}
  end

  @spec pre_validated_field(val, (val -> String.t())) :: {:field, String.t(), valid(val)}
        when val: var
  def pre_validated_field(val, f) do
    {:field, f.(val), {:valid, val}}
  end

  @spec invalidate(field(raw, any()), String.t()) :: {:field, raw, {:invalid, String.t()}}
        when raw: var
  def invalidate({:field, raw, _}, str) when is_binary(str) do
    {:field, raw, {:invalid, str}}
  end

  @spec validate(field(raw, a), validator(raw, a), event(raw)) :: field(raw, a)
        when raw: var, a: var
  def validate({:field, _, _} = field, validator, :on_submit) when validator?(validator) do
    validate_always(field, validator)
  end

  def validate({:field, _, _} = field, validator, :on_blur) when validator?(validator) do
    validate_always(field, validator)
  end

  def validate({:field, _, _} = field, validator, :on_related_change)
      when validator?(validator) do
    validate_if_validated(field, validator)
  end

  def validate({:field, _, validity}, validator, {:on_change, val})
      when validator?(validator) do
    validate_if_validated({:field, val, validity}, validator)
  end

  @spec extract_error(field(any(), any())) :: ExMaybe.t(String.t())
  def extract_error({:field, _, {:invalid, error}}) do
    error
  end

  def extract_error({:field, _, _}) do
    nil
  end

  # Private

  @spec validate_always(field(raw, a), validator(raw, a)) :: field(raw, a) when a: var, raw: var
  defp validate_always({:field, raw, _}, validator) when validator?(validator) do
    {:field, raw, raw |> validator.() |> to_validity()}
  end

  @spec validate_if_validated(field(raw, a), validator(raw, a)) :: field(raw, a)
        when a: var, raw: var
  defp validate_if_validated({:field, _, :not_validated} = field, _) do
    field
  end

  defp validate_if_validated({:field, raw, _}, validator) when validator?(validator) do
    {:field, raw, raw |> validator.() |> to_validity()}
  end

  @spec to_validity(Result.t(String.t(), val)) :: validity(val) when val: var
  defp to_validity({:ok, val}) do
    {:valid, val}
  end

  defp to_validity({:error, msg}) do
    {:invalid, msg}
  end
end
