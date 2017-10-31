defmodule Rexbug.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rexbug,
      version: "0.1.0",
      elixir: "~> 1.3",
      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.html": :test,
        "test": :test,
      ],
      docs: docs(),
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/nietaki/rexbug",
      extras: ["README.md"],
      assets: [],
      # assets: ["assets"],
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # {:meck, "~> 0.8", only: :test},
      {:redbug, "~> 1.0"},
      {:excoveralls, "~> 0.4", only: :test},
      {:ex_doc, "~> 0.14.3", only: :dev}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Jacek Królikowski <nietaki@gmail.com>"],
      links: %{
        "GitHub" => "https://github.com/nietaki/rexbug",
      },
      description: description(),
    ]
  end

  defp description do
    """
    A thin Elixir wrapper for the redbug Erlang tracing debugger.
    """
  end
end
