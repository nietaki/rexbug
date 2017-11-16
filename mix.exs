defmodule Rexbug.Mixfile do
  use Mix.Project

  # RELEASE CHECKLIST
  # - update the version here
  # - update "Installation" section in the README with the new version
  # - check if README is outdated
  # - make sure there's no obviously missing or outdated docs
  # - build and publish the hex package
  #   - mix hex.build
  #   - mix hex.publish

  def project do
    [
      app: :rexbug,
      version: "0.1.0",
      elixir: "~> 1.3",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      source_url: "https://github.com/nietaki/rexbug",

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
    [extra_applications: []]
  end


  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_),     do: ["lib"]


  defp aliases do
    [
      "coveralls": [
        "coveralls --exclude integration",
      ],
      "coveralls.html": [
        "coveralls.html --exclude integration",
      ],
      "coveralls.travis": [
        "coveralls.travis --exclude integration",
      ],
    ]
  end


  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/nietaki/rexbug",
      extras: ["README.md"],
      assets: ["assets"],
      logo: "assets/rexbug64.png",
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
      {:ex_doc, "~> 0.18.1", only: :dev}
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
    Rexbug is a thin Elixir wrapper for :redbug production-friendly Erlang
    tracing debugger. It tries to preserve :redbug's simple and intuitive
    interface while making it more convenient to use by Elixir developers.

    # What does it do?

    It's an Elixir tracing - based debugger. It allows you to connect to a live
    Elixir system and get information when some code inside it is executed. The
    "some code" can be a whole module, a specific function in the module, or
    some function, but only if it's called with some specific arguments. The
    information you can get is the function arguments, its result and the
    stack trace.

    If you want to you can narrow the tracing down to a specific process,
    investigate a remote node or look at the messages sent between processes.

    Rexbug is also production-system-friendly. It has sensible limits for both
    time and amount of trace events after which it stops tracing. This means
    you won't accidentally overload the system and flood your console with
    debug information if your trace pattern wasn't specific enough.
    """
  end
end
