curl -fLO --retry 5 --retry-delay 10 --retry-all-errors https://github.com/lu-zero/cargo-c/releases/download/v0.10.15/Cargo.lock &&
echo "57fab87782a5f9ef46fcbddc44d425b1  Cargo.lock" | md5sum -c
