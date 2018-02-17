defmodule Rexbug.Printing.Utils do
  @moduledoc false

  @printing_opts [limit: -1]

  def printing_inspect(term) do
    inspect(term, @printing_opts)
  end
end
