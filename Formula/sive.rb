class Sive < Formula
  desc "Sync secrets from your vault into your shell"
  homepage "https://github.com/PeachlifeAB/sive"
  url "https://github.com/PeachlifeAB/sive/archive/36205c4aced6078bd06fbe7cec5b39b1a2cd3563.tar.gz"
  version "0.1.0"
  sha256 "55a15976cfeb2f47b592af3c3a79d69611a5a3db0b6bff3e2470a0e6039d1b3b"
  license "MIT"

  depends_on "python@3.13"
  depends_on "uv" => :build

  def install
    system "uv", "pip", "install", "--no-deps", "--python", Formula["python@3.13"].opt_bin/"python3.13", "--prefix", prefix, "."
  end

  test do
    assert_match "sive", shell_output("#{bin}/sive --version")
  end
end
