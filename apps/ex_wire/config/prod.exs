use Mix.Config

config :logger,
  level: :warn,
  # purge logs with lower level than this - removes calls from code
  compile_time_purge_level: :info
