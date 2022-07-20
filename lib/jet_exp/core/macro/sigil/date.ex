defmodule JetExp.Core.Macro.Sigil.Date do
  @moduledoc false

  use JetExp.Core.Macro.Sigil

  @delimiters ~w{- / .}

  @impl JetExp.Core.Macro.Sigil
  def eval(
        <<year::binary-size(4), d::binary-size(1), month::binary-size(2), d::binary-size(1),
          day::binary-size(2)>>
      )
      when d in @delimiters do
    {:ok, build_date(year, month, day)}
  end

  def eval(str) when is_binary(str) do
    {:error, reason: :format}
  end

  def eval(_literal) do
    {:error, reason: :type_slaps, expected_type: :string}
  end

  defp build_date(year, month, day) do
    %{
      "year" => String.to_integer(year),
      "month" => String.to_integer(month),
      "day" => String.to_integer(day)
    }
  end
end
