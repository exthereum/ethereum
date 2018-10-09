defmodule MerklePatriciaTree.Mixfile do
  use Mix.Project

  def project do
    [
      app: :merkle_patricia_tree,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      description: "Ethereum's Merkle Patricia Trie data structure",
      package: [
        maintainers: ["Geoffrey Hayes", "Ayrat Badykov", "Mason Forest"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/exthereum/ethereum"}
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [ignore_warnings: "../../.dialyzer.ignore-warnings"]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Umbrella
      {:hex_prefix, in_umbrella: true},
      {:ex_rlp, in_umbrella: true},

      # Libaries
      {:exleveldb, "~> 0.13"},
      {:keccakf1600, "~> 2.0.0", hex: :keccakf1600_orig},
      {:poison, "~> 4.0.1", only: [:dev, :test], runtime: false},

      # Common
      {:credo, "~> 0.10.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false}
    ]
  end
end
