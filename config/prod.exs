use Mix.Config

config :logger,
  level: :info,
  # purge logs with lower level than this - removes calls from code
  compile_time_purge_level: :info
