# Reproducible Wan 2.2 worker build for Nachiketa aur Yamraj.
FROM wlsdml1114/multitalk-base:1.8 AS runtime

ARG COMFYUI_COMMIT=b133e48368d0f52bb014f0dd7ae1adb7403d515b
ARG MANAGER_COMMIT=f39cbd56fecae0b27a446c0cd450cd591f3a8bea
ARG KJNODES_COMMIT=3f20054214fec9f9234fd3841ae6f1e4287948f6
ARG VFI_COMMIT=26545cc2dd95bc3d27f056016300673bdeee78f5
ARG VHS_COMMIT=115de7a9d9e34410cffb9ecfd268e993b11a50fb
ARG USDU_COMMIT=a5547db9e1d07d3318bb21e9e9c474f4c1e9c8df

RUN pip install --no-cache-dir runpod==1.7.13 websocket-client==1.8.0

WORKDIR /

RUN git clone --filter=blob:none --no-checkout https://github.com/Comfy-Org/ComfyUI.git /ComfyUI && \
    cd /ComfyUI && \
    git checkout "${COMFYUI_COMMIT}" && \
    pip install --no-cache-dir -r requirements.txt

RUN git clone --filter=blob:none --no-checkout https://github.com/Comfy-Org/ComfyUI-Manager.git /ComfyUI/custom_nodes/ComfyUI-Manager && \
    cd /ComfyUI/custom_nodes/ComfyUI-Manager && \
    git checkout "${MANAGER_COMMIT}" && \
    pip install --no-cache-dir -r requirements.txt

RUN git clone --filter=blob:none --no-checkout https://github.com/kijai/ComfyUI-KJNodes.git /ComfyUI/custom_nodes/ComfyUI-KJNodes && \
    cd /ComfyUI/custom_nodes/ComfyUI-KJNodes && \
    git checkout "${KJNODES_COMMIT}" && \
    pip install --no-cache-dir -r requirements.txt

RUN git clone --filter=blob:none --no-checkout https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation && \
    cd /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation && \
    git checkout "${VFI_COMMIT}" && \
    python install.py

RUN git clone --filter=blob:none --no-checkout https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git /ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite && \
    cd /ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite && \
    git checkout "${VHS_COMMIT}" && \
    pip install --no-cache-dir -r requirements.txt

# Ultimate SD Upscale: tile-based diffusion refiner used as a bounded, low-denoise
# face/detail pass after the ESRGAN upscale (stage2). No extra Python deps beyond
# what ComfyUI core already installs; pulls its own vendored script via submodule.
RUN git clone --filter=blob:none --no-checkout https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git /ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale && \
    cd /ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale && \
    git checkout "${USDU_COMMIT}" && \
    git submodule update --init --recursive

RUN set -eu; \
    mkdir -p /ComfyUI/models/text_encoders /ComfyUI/models/vae /ComfyUI/models/diffusion_models /ComfyUI/models/loras; \
    download() { \
        url="$1"; output="$2"; attempt=1; \
        until wget -c --no-verbose --tries=1 --timeout=60 "$url" -O "$output"; do \
            if [ "$attempt" -ge 5 ]; then \
                echo "Download failed after 5 attempts: $url"; \
                return 1; \
            fi; \
            delay=$((attempt * 10)); \
            echo "Download attempt $attempt failed; retrying in ${delay}s: $url"; \
            sleep "$delay"; \
            attempt=$((attempt + 1)); \
        done; \
    }; \
    download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors /ComfyUI/models/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors & pid_one=$!; \
    download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors /ComfyUI/models/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors & pid_two=$!; \
    wait "$pid_one"; wait "$pid_two"; \
    download https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors /ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors & pid_one=$!; \
    download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors /ComfyUI/models/vae/wan_2.1_vae.safetensors & pid_two=$!; \
    wait "$pid_one"; wait "$pid_two"; \
    download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors /ComfyUI/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors & pid_one=$!; \
    download https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors /ComfyUI/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors & pid_two=$!; \
    wait "$pid_one"; wait "$pid_two"
RUN mkdir -p /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife && \
    wget -q https://huggingface.co/hfmaster/models-moved/resolve/cab6dcee2fbb05e190dbb8f536fbdaa489031a14/rife/rife49.pth -O /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth

RUN set -eu; \
    mkdir -p /ComfyUI/models/upscale_models; \
    download() { \
        url="$1"; output="$2"; attempt=1; \
        until wget -c --no-verbose --tries=1 --timeout=60 "$url" -O "$output"; do \
            if [ "$attempt" -ge 5 ]; then \
                echo "Download failed after 5 attempts: $url"; \
                return 1; \
            fi; \
            delay=$((attempt * 10)); \
            echo "Download attempt $attempt failed; retrying in ${delay}s: $url"; \
            sleep "$delay"; \
            attempt=$((attempt + 1)); \
        done; \
    }; \
    download https://huggingface.co/lokCX/4x-Ultrasharp/resolve/main/4x-UltraSharp.pth /ComfyUI/models/upscale_models/4x-UltraSharp.pth

# Base SD1.5 checkpoint used only as the tile-diffusion refiner in stage2's
# Ultimate SD Upscale (No Upscale) pass. Downloaded on its own, AFTER the
# heavy Wan2.2 model stage above (not concurrently with it), to avoid
# competing with the two ~14GB Wan2.2 downloads for bandwidth. The prior
# attempt also had a real bug: it combined the fp32 repo path
# (stable-diffusion-v1-5/stable-diffusion-v1-5) with the fp16 filename --
# a URL never actually verified and almost certainly a 404, which is the
# real reason it failed outright (exit code 1) rather than the bandwidth
# contention I initially assumed. The fp16 file actually lives in a
# DIFFERENT repo (Comfy-Org/stable-diffusion-v1-5-archive), used below --
# this exact URL was verified with curl (200 OK, 2132696762 bytes) before
# writing it here. fp16 also halves the download vs fp32 (2.1GB vs 4.3GB).
RUN set -eu; \
    mkdir -p /ComfyUI/models/checkpoints; \
    download() { \
        url="$1"; output="$2"; attempt=1; \
        until wget -c --no-verbose --tries=1 --timeout=120 "$url" -O "$output"; do \
            if [ "$attempt" -ge 5 ]; then \
                echo "Download failed after 5 attempts: $url"; \
                return 1; \
            fi; \
            delay=$((attempt * 15)); \
            echo "Download attempt $attempt failed; retrying in ${delay}s: $url"; \
            sleep "$delay"; \
            attempt=$((attempt + 1)); \
        done; \
    }; \
    download https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors /ComfyUI/models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors

COPY . .
RUN mkdir -p /ComfyUI/user/default/ComfyUI-Manager
COPY config.ini /ComfyUI/user/default/ComfyUI-Manager/config.ini
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
