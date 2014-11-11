require "formula"

class Harfbuzz < Formula
  homepage "http://www.freedesktop.org/wiki/Software/HarfBuzz"
  url "http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-0.9.33.tar.bz2"
  sha256 "d313c5bf04b8acd01e8f16979d6d2e5fe65184eb28816b70ea0f374be11314c7"

  bottle do
    root_url 'https://juliabottles.s3.amazonaws.com'
    cellar :any
    sha1 "a97e9fdfaa2dd88f567f82933f9b27384d822f47" => :mavericks
    sha1 "3a186489dcb3b81d347f635ebf77499c8db60756" => :mountain_lion
    sha1 "a6b29966264f6272836bdaccbf1b8097f23823e9" => :lion
    sha1 "c2b73e7366dbe38a08a0303f3ccccda5b693541d" => :yosemite
  end

  depends_on "staticfloat/juliadeps/pkg-config" => :build
  depends_on "staticfloat/juliadeps/glib"
  depends_on "staticfloat/juliadeps/cairo"
  depends_on "staticfloat/juliadeps/icu4c" => :recommended
  depends_on "freetype"

  def install
    args = %W[--disable-dependency-tracking --prefix=#{prefix}]
    args << "--with-icu" if build.with? "icu4c"
    system "./configure", *args
    system "make install"
  end
end
