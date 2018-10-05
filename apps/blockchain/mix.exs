defmodule Blockchain.Mixfile do
  use Mix.Project

  def project do
    [
      app: :blockchain,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      description: "Ethereum's Blockchain Manager",
      package: [
        maintainers: ["Geoffrey Hayes", "Ayrat Badykov", "Mason Forest"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/exthereum/ethereum"}
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {Blockchain.Application, []}]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Umbrella
      {:evm, in_umbrella: true},
      {:ex_rlp, in_umbrella: true},
      {:merkle_patricia_tree, in_umbrella: true},

      # Libaries
      {:keccakf1600, "~> 2.0.0", hex: :keccakf1600_orig},
      {:libsecp256k1, "~> 0.1.9"},
      {:poison, "~> 4.0.1"},

      # Common
      {:credo, "~> 0.10.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false},
    ]
  end
end
