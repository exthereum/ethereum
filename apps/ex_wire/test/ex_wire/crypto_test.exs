defmodule ExWire.CryptoTest do
  use ExUnit.Case, async: true
  doctest ExWire.Crypto
  alias ExthCrypto.Signature

  test "recover public key from signature" do
    {signature, _r, _s, recovery_id} =
      Signature.sign_digest("hi mom", ExthCrypto.Test.private_key(:key_a))

    {:ok, public_key} = Signature.recover("hi mom", signature, recovery_id)

    assert public_key == ExthCrypto.Test.public_key(:key_a)
  end
end
