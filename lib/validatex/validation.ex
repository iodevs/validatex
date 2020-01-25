defmodule Validatex.Validation do
  @moduledoc """
  This module helps with validation of input forms.
  """

  alias Validatex.MapExtra

  @type key() :: String.t() | atom()

  @type error() :: String.t()
  @type errors() :: [error()]
  @type error_or_errors :: error() | errors()
  @type validator(a, b) :: (a -> Result.t(error_or_errors(), b))

  @type not_validated() :: :not_validated
  @type valid(a) :: {:valid, a}
  @type invalid() :: {:invalid, error_or_errors()}

  @typedoc """
  This type defines three state of `field` (or simply consider the `field` as an input form):

  * `not_validated()`: it's default value and mean it that input form has not validated yet,
  * `valid(a)`: input form has been validated and has a valid value,
  * `invalid()`: in opposite case, it has invalid value and thus contain one or more error messages.
  """
  @type validity(a) :: not_validated() | valid(a) | invalid()

  @typedoc """
  Defines `field` data type. It contains a (`raw`) value from input form
  and an information about validation of this value.
  """
  @type field(raw, a) :: {:field, raw, validity(a)}

  @typedoc """
  Defines `optional_field` data type. For cases when you need optional an input form.
  """
  @type optional_field(raw, a) :: field(raw, ExMaybe.t(a))

  @type on_submit() :: :on_submit
  @type on_blur() :: :on_blur
  @type on_related_change() :: :on_related_change
  @type on_change(val) :: {:on_change, val}

  @typedoc """
  Event describes four different action for `field`s:

  * `on_blur()` validates `field` when user leaves an input form
  * `on_change(raw)` validates `field` when user changes value in input field
  * `on_related_change()` validates `field` which is tied with another `field`,
    for example: password and his confirm form
  * `on_submit()` validates all model data (it means all fields) before submitting to server
  """
  @type event(raw) :: on_submit() | on_blur() | on_related_change() | on_change(raw)

  @type model() :: %{required(key()) => field(any(), any())}

  @doc """
  Guard for verifying if key of map is atom or binary.
  """
  defguard key?(k) when is_binary(k) or is_atom(k)

  @doc """
  Guard for verifying if validation function has an arity equal to 1.
  """
  defguard validator?(f) when is_function(f, 1)

  @doc """
  Gets `raw` value from `field`.

      iex> {:field, "bar", :not_validated} |> Validatex.Validation.raw_value()
      "bar"

  """
  @spec raw_value(field(raw, any())) :: raw when raw: var
  def raw_value({:field, raw, _}) do
    raw
  end

  @doc """
  Gets `validity` from `field`.

      iex> {:field, "bar", :not_validated} |> Validatex.Validation.validity()
      :not_validated

  """
  @spec validity(field(any(), a)) :: validity(a) when a: var
  def validity({:field, _, validity}) do
    validity
  end

  @doc """
  Defines `field` with `:not_validated` validity. It's used as init value of your forms,
  e.g. for name, password,...
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L157)
  of using.

      iex> Validatex.Validation.field("foo")
      {:field, "foo", :not_validated}

  """
  @spec field(raw) :: {:field, raw, :not_validated} when raw: var
  def field(raw) do
    {:field, raw, :not_validated}
  end

  @doc """
  Has similar functionality as for `field`. But in this case is for an optional input form.
  """
  @spec optional_field(raw) :: {:field, raw, :not_validated} when raw: var
  def optional_field(raw) do
    field(raw)
  end

  @doc """
  If you need to have the `field` with `valid(a)` validity.

      iex> "5" |> Validatex.Validation.pre_validated_field(& &1)
      {:field, "5", {:valid, "5"}}

  """
  @spec pre_validated_field(val, (val -> String.t())) :: {:field, String.t(), valid(val)}
        when val: var
  def pre_validated_field(val, f) do
    {:field, f.(val), {:valid, val}}
  end

  @doc """
  If you need to have the `field` with `invalid()` validity. Then you have to add an error
  message.

      iex> Validatex.Validation.field("bar") |> Validatex.Validation.invalidate("Expected foo!")
      {:field, "bar", {:invalid, "Expected foo!"}}

  """
  @spec invalidate(field(raw, any()), String.t()) :: {:field, raw, {:invalid, error()}}
        when raw: var
  def invalidate({:field, raw, _}, err) when is_binary(err) or is_list(err) do
    {:field, raw, {:invalid, err}}
  end

  @doc """
  Applying function on concrete or all valid `field`s according to your needs.

      iex> nv = Validatex.Validation.field("bar")
      {:field, "bar", :not_validated}
      iex> pv = Validatex.Validation.pre_validated_field("foo", & &1)
      {:field, "foo", {:valid, "foo"}}
      iex> data = %{"name" => nv, "surname" => pv}
      %{
        "name" => {:field, "bar", :not_validated},
        "surname" => {:field, "foo", {:valid, "foo"}}
      }
      iex> Validatex.Validation.apply(data, ["name", "surname"], & &1)
      {:invalid, "'name' field isn't valid.'"}
      iex> Validatex.Validation.apply(data, ["surname"],
      ...> fn %{"surname" => s} -> %{"surname" => String.capitalize(s)} end)
      {:valid, %{"surname" => "Foo"}}

  """
  @spec apply(%{required(key()) => field(any(), a)}, [key()], (%{required(key()) => a} -> b)) ::
          validity(b)
        when a: var, b: var
  def apply(data, fields, f) when is_map(data) and is_list(fields) and is_function(f, 1) do
    data
    |> take(fields)
    |> map(f)
  end

  @doc """
  Gets error from `field`.

      iex> Validatex.Validation.field("bar") |>
      ...> Validatex.Validation.invalidate("Expected foo!") |>
      ...> Validatex.Validation.extract_error()
      "Expected foo!"

  """
  @spec extract_error(field(any(), any())) :: ExMaybe.t(error_or_errors())
  def extract_error({:field, _, {:invalid, error}}) do
    error
  end

  def extract_error({:field, _, _}) do
    nil
  end

  @doc """
  Validation of optional variable.

      iex> f = Validatex.Validation.optional(&Validatex.Validators.not_empty(&1))
      iex> f.("")
      {:ok, nil}
      iex> f.("foo")
      {:ok, "foo"}

  """
  @spec optional(validator(String.t(), a)) :: validator(String.t(), ExMaybe.t(a)) when a: var
  def optional(validator) when validator?(validator) do
    fn
      "" ->
        {:ok, nil}

      raw when is_binary(raw) ->
        validator.(raw)
    end
  end

  @doc """
  Verification if `field` has valid value.

      iex> "5" |> Validatex.Validation.pre_validated_field(& &1) |> Validatex.Validation.valid?()
      true

      iex> {:field, "bar", :not_validated} |> Validatex.Validation.valid?()
      false

  """
  @spec valid?(field(any(), any())) :: boolean()
  def valid?({:field, _, {:valid, _}}), do: true
  def valid?(_), do: false

  @doc """
  Runs validation on map which contains `field`s with given validator for `on_blur` event action.
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L110)
  of using.
  """
  @spec validate_on_blur(model(), key(), validator(any(), any())) :: model()
  def validate_on_blur(map, field, validator) when is_map(map) and key?(field) do
    Map.update!(
      map,
      field,
      &validate(&1, validator, :on_blur)
    )
  end

  @doc """
  Runs validation on map which contains `field`s with given validator for `on_change` event action.
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L92)
  of using.
  """
  @spec validate_on_change(model(), key(), any(), validator(any(), any())) :: model()
  def validate_on_change(map, field, value, validator) when is_map(map) and key?(field) do
    Map.update!(
      map,
      field,
      &validate(&1, validator, {:on_change, value})
    )
  end

  @doc """
  Runs validation on map which contains `field`s with given validator for `on_related_change` event action.
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L31)
  of using.
  """
  @spec validate_on_related_change(model(), key(), key(), validator(any(), any())) :: model()
  def validate_on_related_change(map, field, related_field, validator)
      when is_map(map) and key?(field) and key?(related_field) and validator?(validator) do
    related = MapExtra.get!(map, related_field)

    Map.update!(
      map,
      field,
      &validate(&1, validator.(related), :on_related_change)
    )
  end

  @doc """
  Runs validation on map which contains `field`s with given validator for `on_submit` event action.
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L123)
  of using.
  """
  @spec validate_on_submit(model(), key(), validator(any(), any())) :: model()
  def validate_on_submit(map, field, validator)
      when is_map(map) and key?(field) and validator?(validator) do
    Map.update!(
      map,
      field,
      &validate(&1, validator, :on_submit)
    )
  end

  @doc """
  Runs validation for `field` which is tied with another `field` with `on_submit` event action.
  For example `password` and `confirm_password`.

  **Important note**: This function has to be placed immediately after calling `validate_on_submit` function.
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L123)
  of using.
  """
  @spec validate_on_related_submit(model(), key(), key(), validator(any(), any())) :: model()
  def validate_on_related_submit(map, field, related_field, validator)
      when is_map(map) and key?(field) and key?(related_field) and validator?(validator) do
    validate_on_submit(map, field, validator.(MapExtra.get!(map, related_field)))
  end

  @doc """
  If all `field`s have a valid values then you can use this function to send these data to server.
  See [example](https://github.com/iodevs/validatex_example/blob/master/lib/server_web/live/user/register_live.ex#L123)
  of using.
  """
  @spec submit_if_valid(
          %{required(key()) => field(any(), a)},
          [key()],
          (%{required(key()) => a} -> b)
        ) ::
          b
        when a: var, b: Result.t(any(), any())
  def submit_if_valid(data, fields, f)
      when is_map(data) and is_list(fields) and is_function(f, 1) do
    data
    |> take(fields)
    |> to_result()
    |> Result.and_then(f)
  end

  @doc """
  Runs validation for `field` with given validator and event action.

      iex> nv = Validatex.Validation.field("bar")
      {:field, "bar", :not_validated}
      iex> Validatex.Validation.validate(nv, &Validatex.Validators.not_empty(&1), :on_submit)
      {:field, "bar", {:valid, "bar"}}
      iex> Validatex.Validation.validate(nv,
      ...> &Validatex.Validators.not_empty(&1),
      ...> {:on_change, "foo"})
      {:field, "foo", :not_validated}

  """
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

  @spec to_validity(Result.t(error_or_errors(), val)) :: validity(val) when val: var
  defp to_validity({:ok, val}) do
    {:valid, val}
  end

  defp to_validity({:error, err}) do
    {:invalid, err}
  end

  @spec take(%{required(key()) => field(any(), a)}, [key()]) :: validity(%{required(key()) => a})
        when a: var
  defp take(data, fields) when is_map(data) and is_list(fields) do
    Enum.reduce_while(
      fields,
      {:valid, %{}},
      fn field, {:valid, acc} ->
        case data |> Map.get(field) |> validity() do
          {:valid, value} ->
            {:cont, {:valid, Map.put(acc, field, value)}}

          _ ->
            {:halt, {:invalid, "'#{field}' field isn't valid.'"}}
        end
      end
    )
  end

  @spec map(validity(a), (a -> b)) :: validity(b) when a: var, b: var
  defp map({:valid, data}, f) when is_function(f, 1) do
    {:valid, f.(data)}
  end

  defp map(validity, _f) do
    validity
  end

  @spec to_result(validity(a)) :: Result.t(error_or_errors(), a) when a: var
  defp to_result({:valid, data}), do: {:ok, data}
  defp to_result({:invalid, err}), do: {:error, err}
  defp to_result(:not_validated), do: {:error, "Not validated"}
end
