defmodule EVM.Mixfile do
  use Mix.Project

  def project do
    [
      app: :evm,
      version: "0.2.0",
      elixir: "~> 1.7",
      description: "Ethereum's Virtual Machine, in all its glory.",
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
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {EVM.Application, []}]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Umbrella
      {:ex_rlp, in_umbrella: true},
      {:merkle_patricia_tree, in_umbrella: true},

      # Libraries
      {:keccakf1600, "~> 2.0.0", hex: :keccakf1600_orig},
      {:poison, "~> 4.0.1", only: [:dev, :test]},

      # Common
      {:credo, "~>  0.10.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false},
    ]
  end
end
