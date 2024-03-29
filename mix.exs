defmodule Rexbug.Mixfile do
  use Mix.Project

  #
  # # RELEASE CHECKLIST
  #
  # 1. update the version here
  # 2. update CHANGELOG.md
  # 3. update "Installation" section in the README with the new version
  # 4. check if README is outdated
  # 5. run ./scripts/release.sh
  #

  def project do
    [
      app: :rexbug,
      version: "2.0.0-rc1",
      elixir: ">= 1.11.4",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      source_url: "https://github.com/nietaki/rexbug",
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        coverage: :test,
        "coverage.html": :test,
        "coveralls.html": :test,
        "coveralls.post": :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        test: :test,
        "test.watch": :test
      ],
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: []]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "coverage.html": ["coveralls.html --exclude integration --include coveralls_safe"],
      coverage: ["coveralls --exclude integration --include coveralls_safe"],
      "rexbug.check": ["format", "dialyzer", "credo", "docs"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/nietaki/rexbug",
      extras: ["README.md"],
      assets: ["assets"],
      logo: "assets/rexbug64.png",
      groups_for_modules: [
        "Main Modules": [Rexbug, Rexbug.Dtop],
        "Support Modules": ~r/.*/
      ]
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
      {:redbug, "~> 2.0"},

      # test/housekeeping stuff
      {:credo, "~> 1.0", only: [:dev], optional: true, runtime: false},
      {:dialyxir, ">= 1.0.0", only: [:dev], optional: true, runtime: false},
      {:ex_doc, ">= 0.18.0", optional: true, only: :dev},
      {:excoveralls, "~> 0.16", optional: true, only: :test},
      {:mix_test_watch, ">= 0.5.0", optional: true, runtime: false, only: [:dev, :test]}
    ]
  end

  defp package do
    [
      build_tools: ["mix"],
      licenses: ["MIT"],
      maintainers: ["Jacek Królikowski <nietaki@gmail.com>"],
      links: %{
        "GitHub" => "https://github.com/nietaki/rexbug"
      },
      description: description()
    ]
  end

  defp description do
    """
    Rexbug is a thin Elixir wrapper for :redbug production-friendly Erlang
    tracing debugger. It tries to preserve :redbug's simple and intuitive
    interface while making it more convenient to use by Elixir developers.
    """
  end
end
