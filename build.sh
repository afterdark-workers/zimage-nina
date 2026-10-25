#!/bin/sh
# Z-Image Nina — everything the worker image needs. The Dockerfile in your copy downloads this file
# from the original repo on every build, so fixes made there reach you with a rebuild.
set -eu
case "${CIVITAI_TOKEN:-}" in ""|PASTE_*) echo "ERROR: set CIVITAI_TOKEN at the top of the Dockerfile" >&2; exit 1;; esac

# file <dest> <url> <sha256>
file() {
  wget -q -O "$1" "$2"
  echo "$3  $1" | sha256sum -c - || { echo "ERROR: $1 changed upstream — wait for an update of the original repo, then rebuild" >&2; exit 1; }
}

# Civitai 2608040 / version 2928446 (11.5 GB)
file /comfyui/models/diffusion_models/zimage_nina_v01.safetensors \
  "https://civitai.com/api/download/models/2928446?fileId=2807233&token=${CIVITAI_TOKEN}" \
  c40292c49d177f24153818a89407a046393538e62033346505842fa072f51c26

# Comfy-Org/Z-Image-Turbo (Apache 2.0) (8.0 GB)
file /comfyui/models/text_encoders/qwen_3_4b.safetensors \
  "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/text_encoders/qwen_3_4b.safetensors" \
  6c671498573ac2f7a5501502ccce8d2b08ea6ca2f661c458e708f36b36edfc5a

# Comfy-Org/Z-Image-Turbo (0.3 GB)
file /comfyui/models/vae/ae.safetensors \
  "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/vae/ae.safetensors" \
  afc8e28272cd15db3919bacdb6918ce9c1ed22e96cb12c4d5ed0fba823529e38

# ComfyUI 0.34.0 (base image) → 0.39.0 — Z-Image needs 0.36+. Install into /opt/venv (the one ComfyUI actually runs with).
cd /comfyui
git fetch --depth 1 https://github.com/Comfy-Org/ComfyUI.git tag v0.39.0
git checkout -f v0.39.0
uv pip install --python /opt/venv/bin/python -r requirements.txt "transformers>=4.50.3,<5" "huggingface-hub<1.0"
timeout 300 /opt/venv/bin/python main.py --quick-test-for-ci --cpu
