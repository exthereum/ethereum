# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set output_dir: "_build/"
  set dev_mode: false
  set include_erts: true
  set cookie: :"`ybR3Te$f;/5OwNL^B/x,47Ik)SvZa81Q[&8WukUZ~XvHT)Eg%?&w1^yY`|Er3.2"
end

environment :prod do
  set output_dir: "_build/"
  set include_erts: true
  set include_src: false
  set cookie: :"f<,RX%KGkI@n6%=<qV!W9(hm!8!~{xBqfAzwwIs1GHX:YXE%:j<?U2>iE)6bcKh,"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :ethereum do
  set version: "#{System.get_env("RELEASE_VERSION")}"
  set applications: [
    :runtime_tools,
    abi: :permanent,
    blockchain: :permanent,
    evm: :permanent,
    ex_rlp: :permanent,
    ex_wire: :permanent,
    exth_crypto: :permanent,
    hex_prefix: :permanent,
    merkle_patricia_tree: :permanent
  ]
end

