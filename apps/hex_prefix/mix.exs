defmodule HexPrefix.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hex_prefix,
      version: "0.2.0",
      elixir: "~> 1.7",
      description: "Ethereum's Hex Prefix encoding",
      package: [
        maintainers: ["Geoffrey Hayes", "Ayrat Badykov"],
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
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Umbrella

      # Libaries

      # Common
      {:credo, "~> 0.10.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.19.1", only: :dev, runtime: false},
    ]
  end
end
