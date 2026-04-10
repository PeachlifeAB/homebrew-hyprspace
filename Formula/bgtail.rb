class Bgtail < Formula
  desc "Run long-running commands detached with minimal heartbeat"
  homepage "https://github.com/PeachlifeAB/bgtail"
  url "https://github.com/PeachlifeAB/bgtail/archive/refs/tags/0.1.0.tar.gz"
  sha256 "8c93bca964e15df0ebc17a1fee1b54e5a5c74a578b2993fc79adc171a20e6912"
  license "MIT"

  depends_on "uv" => :build
  depends_on :macos
  depends_on "python@3.13"

  def install
    python = Formula["python@3.13"].opt_bin/"python3.13"
    system "uv", "pip", "install", "--no-deps", "--python", python, "--prefix", prefix, "."
  end

  test do
    assert_match "0.1.0", shell_output("#{bin}/bgtail --version")
  end
end
