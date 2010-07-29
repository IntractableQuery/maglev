require File.expand_path('simple', File.dirname(__FILE__))

require 'openssl'

$md_algorithms = if defined? Maglev
                   OpenSSL::Digest::SUPPORTED_DIGESTS
                 else
                   %w(MD2 MD4 MD5 MDC2 RIPEMD160 SHA SHA1
                      SHA224 SHA256 SHA384 SHA512 DSS1)
                 end

def test_basic_ruby_use_case
  digest = OpenSSL::Digest.const_get('SHA1').new
  secret = 'duh'
  data = 'some secret data'
  hex = OpenSSL::HMAC.hexdigest(digest, secret, data)
  test(hex, "3107ffa818b9c5352860910ef7d259152f9baed8", 'hexdigest')
end

def test_hmac_reset
  digest = OpenSSL::Digest.const_get('SHA1').new
end

def test_all_hmac_impls
  secret = 'duh'
  data = 'some secret data'
  expected = {
    'SHA1'      => "3107ffa818b9c5352860910ef7d259152f9baed8",
    'MD2'       => "6eefda2c12c56068aa8f01ac208acc71",
    'MD4'       => "407a1ea0cd436cb576f76466363ea0d2",
    'MD5'       => "ee1673fb62b595c9d3eb152c7fd910ef",
    'MDC2'      => "1beb4b8bb5b401f8f7aebe17d32d2fef",
    'RIPEMD160' => "c4405a7f019da35571b6d4a260486f1ce6ce4dfe",
    'SHA'       => "f69a6ff233cdf7cc225591df5be6aa25469ccbd9",
    'SHA224'    => "b37410dc0a987bc15ee067c6c1ac63edf7e6f24c43a65473a267c836",
    'SHA256'    => "0f908ba6d41f5c4efde57086137c67abe2202d0422c18f35f480b558b9d6b659",
    'SHA384'    => "a9d6dac0095ccb8adeab243fb4b6fff88482e74b73dc363b595a3c93224ef445dac996041c132bb3aebc39a406921f43",
    'SHA512'    => "562a12945349bdb76bc13e4b4590f15bfb1416d7b17f1d180fb84470a1889a57c97b9abbc38dea8ac4731829dd570a033aff6a3b7a7d3e3033ace97f1e6e0197",
    'DSS1'      => "3107ffa818b9c5352860910ef7d259152f9baed8"
  }

  $md_algorithms.each do |md_type|
    digest = OpenSSL::Digest.const_get(md_type).new
    actual = OpenSSL::HMAC.hexdigest(digest, secret, data)
    test(actual, expected[md_type], "hmac algorithm #{md_type}")
  end
end

def test_crypto_digest
  $md_algorithms.each do |name|
    begin
      md = OpenSSL::Digest.new(name)
      test(md.nil?, false, "OpenSSL::Digest.new(#{name.inspect})")
      test(md.name, name, "#{name} .name")
    rescue RuntimeError => e
      p e
    end
  end

  md = OpenSSL::Digest::SHA1.new
  test(md.nil?, false, "OpenSSL::Digest::SHA1.new")
end

def test_sha1
  bogus = OpenSSL::LibCrypto.EVP_get_digestbyname('BOGUS')
  test(bogus.null?, true, "EVP_get_digestbyname BOGUS")

  sha1 = OpenSSL::LibCrypto.EVP_get_digestbyname('SHA1')
  test(sha1.null?, false, "EVP_get_digestbyname SHA1")
end

def test_openssl_module
  if defined? Maglev
    test(OpenSSL::OPENSSL_VERSION, 'OpenSSL 0.9.8j 07 Jan 2009', 'OPENSSL_VERSION')
    test(OpenSSL::OPENSSL_VERSION_NUMBER, "0x009080af".hex, 'OPENSSL_VERSION_NUMBER')
  end
  test(OpenSSL::VERSION, '1.0.0', 'VERSION')
  test(OpenSSL.debug, false, 'Default value of debug')
end

# TODO: This one is broken....
def test_use_md_specific_classes
  digest = OpenSSL::Digest.const_get('SHA1').new
  digest.update('ff')
  p digest.hexdigest
end

test_sha1 if defined? Maglev
test_crypto_digest
test_basic_ruby_use_case
test_openssl_module
test_all_hmac_impls

report
