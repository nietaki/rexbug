defmodule Foo do
  @moduledoc false

  defstruct [:fa, :fb]

  def foo(a) do
    a
  end

  defmodule Bar do
    @moduledoc false

    defstruct [:ba, :bb]

    def abc() do
    end

    def xyz(_a, _b, _c) do
    end
  end
end
