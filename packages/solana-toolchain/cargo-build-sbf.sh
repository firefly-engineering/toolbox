#!/usr/bin/env bash
# Host-independent cargo-build-sbf.
#
# cargo-build-sbf needs (a) the platform-tools sbpf toolchain and (b)
# rustup, which it uses to link that toolchain and run `cargo +<name>`.
# This wrapper supplies both from Nix and never touches the host's
# rustup: it points at the pinned SBF SDK, uses an isolated RUSTUP_HOME,
# and registers the platform-tools rust as the default toolchain (which
# also satisfies the pre-build `cargo metadata`). --skip-tools-install
# stops any network fetch.
set -euo pipefail

export SBF_SDK_PATH="${SBF_SDK_PATH:-@sbfSdk@/sbf}"
export RUSTUP_HOME="${RUSTUP_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/solana-toolchain/rustup}"
export PATH="@rustup@/bin:$PATH"

mkdir -p "$RUSTUP_HOME"
rustup toolchain link sbf-platform-tools "$SBF_SDK_PATH/dependencies/platform-tools/rust" 2>/dev/null || true
rustup default sbf-platform-tools >/dev/null 2>&1 || true

exec @cargoBuildSbf@ --skip-tools-install "$@"
