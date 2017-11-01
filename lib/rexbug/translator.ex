defmodule Rexbug.Translator do

  @valid_actions [:return, :stack]

  {:ok,
    {:when, [line: 44], [
      {
        {:., [line: 44], [
            {:__aliases__, [line: 44], [:Mainframe, :Server]},
            :foo
          ]
        },
        [line: 44], [
          1, :atom, {:a, [line: 44], nil}
        ]
      },
      {:and, [line: 44], [
          {:<, [line: 44], [{:a, [line: 44], nil}, 1]}, true]}]}}

  @spec translate(elixir_code :: String.t) :: {:ok, charlist} | {:error, atom}

  def translate(elixir_code) do
    String.to_charlist(elixir_code)
  end


  @type action :: :return | :stack
  @spec translate_actions([action] | action) :: {:ok, charlist} | {:error, atom}

  def translate_actions(action) when action in [:return, :stack] do
    translate_actions([action])
  end

  def translate_actions(falsy) when falsy in [nil, false] do
    translate_actions([])
  end

  def translate_actions([]) do
    {:ok, ''}
  end

  def translate_actions(actions) when is_list(actions) do
    if Enum.all?(actions, &(&1 in @valid_actions)) do
      translated = actions
      |> Enum.uniq()
      |> Enum.map(&to_string/1)
      |> Enum.join(";")
      |> String.to_charlist()
      |> prepend_arrow()

      {:ok, translated}
    else
      {:error, :invalid_actions}
    end
  end

  def translate_actions(_), do: {:error, :invalid_actions}


  #---------------------------------------------------------------------------
  # Internal Functions
  #---------------------------------------------------------------------------

  @spec prepend_arrow(action_spec :: charlist) :: charlist
  defp prepend_arrow(action_spec) do
    ' -> ' ++ action_spec
  end

end
