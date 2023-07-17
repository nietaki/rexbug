defmodule Rexbug.Utils do
  @moduledoc false
  @spec collapse_errors([{:ok, term} | {:error, term}]) :: {:ok, [term]} | {:error, term}
  def collapse_errors(tuples) do
    # we could probably play around with some monads for this
    first_error = Enum.find(tuples, :no_error_to_collapse, fn res -> !match?({:ok, _}, res) end)

    case first_error do
      :no_error_to_collapse ->
        results = Enum.map(tuples, fn {:ok, res} -> res end)
        {:ok, results}

      err ->
        err
    end
  end
end
