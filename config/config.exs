# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :karibuex, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:karibuex, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :karibuex, port: 5000
config :karibuex, modules: [UserModuleTest]
config :karibuex, timeout: 1000
config :karibuex, workers: 10

config :karibuex, formatter: Karibu.Logger.Formatter

# config :karibuex, log: "log/#{Mix.env}.log"
# config :karibuex, error_log: "log/#{Mix.env}.error.log"

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
