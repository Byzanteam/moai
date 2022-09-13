defmodule Moai.Core.Macro.Sigil.Date do
  @moduledoc false

  use Moai.Core.Macro.Sigil

  @date_delimiters ~w{- / .}
  @date_time_delimiters [" ", "T"]
  @time_delimiters ~w{:}

  @impl Moai.Core.Macro.Sigil
  def eval(
        <<year::binary-size(4), d::binary-size(1), month::binary-size(2), d::binary-size(1),
          day::binary-size(2), dt::binary-size(1), hour::binary-size(2), t::binary-size(1),
          minute::binary-size(2), t::binary-size(1), second::binary-size(2)>>
      )
      when d in @date_delimiters and dt in @date_time_delimiters and t in @time_delimiters do
    {:ok, build_date(year, month, day, hour, minute, second)}
  end

  def eval(str) when is_binary(str) do
    {:error, reason: :format}
  end

  def eval(_literal) do
    {:error, reason: :type_slaps, expected_type: :string}
  end

  defp build_date(year, month, day, hour, minute, second) do
    %{
      "year" => String.to_integer(year),
      "month" => String.to_integer(month),
      "day" => String.to_integer(day),
      "hour" => String.to_integer(hour),
      "minute" => String.to_integer(minute),
      "second" => String.to_integer(second)
    }
  end
end
