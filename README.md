# Karibuex

. RPC Server [protocol karibu]

## Installation

The package can be installed as:

  1. Add karibuex to your list of dependencies in `mix.exs`:

        def deps do
          [{:karibuex, git: "git@gitlab.visibleo.fr:visibleornd/karibuex.git"}]
        end

  2. Ensure karibuex is started before your application:

        def application do
          [applications: [:karibuex]]
        end

  3. add karibuex configuration for the project to `config/config.exs`:

        config :karibuex, port: 5000
        config :karibuex, modules: [UserModuleTest]
        config :karibuex, timeout: 1000
        config :karibuex, workers: 10


  4. add logger configuration to `config/config.exs`

        config :logger, backends: [{LoggerFileBackend, :info}, {LoggerFileBackend, :error}, :console]

        config :logger, :console,
          format: "[$level] [$date $time] $message\n"

        config :logger, :info,
          path: "log/#{Mix.env}.log",
          level: :info,
          format: "[$level] [$date $time] $message\n"

        config :logger, :error,
          path: "log/#{Mix.env}.error.log",
          level: :error,
          format: "[$level] [$date $time] $message\n"
