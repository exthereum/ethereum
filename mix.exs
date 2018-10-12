defmodule Ethereum.MixProject do
  use Mix.Project

  def project do
    [
      app: :ethereum,
      version: "0.2.0",
      elixir: "~> 1.7",
      description: "Exthereum - The Elixir Ethereum Client",
      elixirc_options: [warnings_as_errors: true],
      package: [
        maintainers: [
          "Geoffrey Hayes",
          "Ayrat Badykov",
          "Mason Fischer",
          "Antoine Toulme",
          "Ino Murko"
        ],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/exthereum/ethereum"}
      ],
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [:underspecs, :unknown, :unmatched_returns],
        plt_add_apps: [:mix, :iex, :logger],
        plt_add_deps: :transitive
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 0.10.2", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
    ]
  end
end
