defmodule Moai.Core.Library.DateTime do
  @moduledoc false

  use Moai.Core.Library.Builder, namespace: "DateTime"

  @typep date_time() :: %{required(String.t()) => non_neg_integer()}

  @doc """
  Extracts given component of date time.

  ## Examples

    iex> dt_extract(%{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 50
    ...> }, "year")
    {:ok, 2020}
  """
  @fun_meta {:year, impl: :dt_extract, signature: ["date_time", :number], extra_args: ["year"]}
  @fun_meta {:month, impl: :dt_extract, signature: ["date_time", :number], extra_args: ["month"]}
  @fun_meta {:day, impl: :dt_extract, signature: ["date_time", :number], extra_args: ["day"]}
  @fun_meta {:hour, impl: :dt_extract, signature: ["date_time", :number], extra_args: ["hour"]}
  @fun_meta {:minute,
             impl: :dt_extract, signature: ["date_time", :number], extra_args: ["minute"]}
  @fun_meta {:second,
             impl: :dt_extract, signature: ["date_time", :number], extra_args: ["second"]}
  @spec dt_extract(date_time(), component :: String.t()) :: {:ok, non_neg_integer()}
  def dt_extract(date_time, component) do
    {:ok, Map.fetch!(date_time, component)}
  end

  @doc """
  Add n seconds to a date time.

  ## Examples

    iex> dt_add_seconds(%{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 50
    ...> }, 13)
    {:ok, %{
      "year" => 2020,
      "month" => 10,
      "day" => 24,
      "hour" => 13,
      "minute" => 29,
      "second" => 3
    }}

    iex> dt_add_seconds(%{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 50
    ...> }, -13)
    {:ok, %{
      "year" => 2020,
      "month" => 10,
      "day" => 24,
      "hour" => 13,
      "minute" => 28,
      "second" => 37
    }}

    iex> dt_add_seconds(%{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 50
    ...> }, 13.2)
    {:ok, nil}
  """
  @fun_meta {:add_seconds, impl: :dt_add_seconds, signature: ["date_time", :number, "date_time"]}
  @spec dt_add_seconds(date_time(), number()) :: {:ok, date_time() | nil}
  def dt_add_seconds(date_time, seconds) when is_integer(seconds) do
    date_time = to_naive_datetime(date_time)

    %{
      year: year,
      month: month,
      day: day,
      minute: minute,
      hour: hour,
      second: second
    } = NaiveDateTime.add(date_time, seconds, :second)

    {:ok,
     %{
       "year" => year,
       "month" => month,
       "day" => day,
       "minute" => minute,
       "hour" => hour,
       "second" => second
     }}
  end

  def dt_add_seconds(_date_time, _seconds) do
    {:ok, nil}
  end

  @doc """
  Subtracts date_time2 from date_time1.

  ## Examples

    iex> dt_diff_seconds(%{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 50
    ...> }, %{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 33
    ...> })
    {:ok, 17}

    iex> dt_diff_seconds(%{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 33
    ...> }, %{
    ...>   "year" => 2020,
    ...>   "month" => 10,
    ...>   "day" => 24,
    ...>   "hour" => 13,
    ...>   "minute" => 28,
    ...>   "second" => 50
    ...> })
    {:ok, -17}
  """
  @fun_meta {:diff_seconds,
             impl: :dt_diff_seconds, signature: ["date_time", "date_time", :number]}
  @spec dt_diff_seconds(date_time(), date_time()) :: {:ok, integer()}
  def dt_diff_seconds(date_time1, date_time2) do
    {:ok,
     NaiveDateTime.diff(
       to_naive_datetime(date_time1),
       to_naive_datetime(date_time2),
       :second
     )}
  end

  defp to_naive_datetime(date_time) do
    NaiveDateTime.new!(
      Map.fetch!(date_time, "year"),
      Map.fetch!(date_time, "month"),
      Map.fetch!(date_time, "day"),
      Map.fetch!(date_time, "hour"),
      Map.fetch!(date_time, "minute"),
      Map.fetch!(date_time, "second")
    )
  end
end
