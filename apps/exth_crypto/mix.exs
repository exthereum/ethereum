defmodule ExthCrypto.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exth_crypto,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      description: "Exthereum's Crypto Suite.",
      package: [
        maintainers: ["Geoffrey Hayes", "Mason Fischer"],
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
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Umbrella

      # Libraries
      {:binary, "~> 0.0.4"},
      {:keccakf1600, "~> 2.0.0", hex: :keccakf1600_orig},
      {:libsecp256k1, "~> 0.1.9"},

      # Common
      {:credo, "~> 0.10.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false}
    ]
  end
end
