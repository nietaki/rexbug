defmodule Rexbug.Dtop do
  @moduledoc """
  TODO describe the information displayed in the table
  """

  @type sort_type() :: :msgs | :cpu | :mem
  @type opt() :: {:sort, sort_type()} | {:max_procs, integer()}

  @help_message """
  Starts/stops (toggles) dtop.

  When dtop is running it will periodically print most "active" processes
  along with

  ## Supported options

  **sort** chooses the sorting for the processes. Supported values are
  `:msgs`, `:cpu`, and `:mem` - all sorted in the descending order.

  `sort` defaults to `:cpu`

  **max_procs** sets the maximum number of processes for which dtop should be run.

  If there's more than `max_procs` running on the machine, `dtop` dtop will
  not print any process info, just the header. This is to avoid oveloading the VM.

  `max_procs` defaults to `1_500`.

  ---

  See the `Rexbug.Dtop` module docs for more information
  """

  Module.register_attribute(__MODULE__, :toggle_doc, accumulate: false, persist: true)
  @toggle_doc @help_message

  @doc @toggle_doc
  @spec toggle([opt()] | %{}) :: term()
  def toggle(opts \\ [])

  def toggle(map) when is_map(map) do
    do_dtop(map)
  end

  def toggle(list) when is_list(list) do
    if Keyword.keyword?(list) do
      do_dtop(Map.new(list))
    else
      print_help()
    end
  end

  def toggle(_), do: print_help()

  defp do_dtop(map) when is_map(map) do
    :redbug.dtop(map)
  end

  defp print_help() do
    IO.puts(@help_message)
  end
end
