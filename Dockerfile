# Reproducible Wan 2.2 worker build for Nachiketa aur Yamraj.
FROM wlsdml1114/multitalk-base:1.8 AS runtime

ARG COMFYUI_COMMIT=b133e48368d0f52bb014f0dd7ae1adb7403d515b
ARG MANAGER_COMMIT=f39cbd56fecae0b27a446c0cd450cd591f3a8bea
ARG KJNODES_COMMIT=3f20054214fec9f9234fd3841ae6f1e4287948f6
ARG VFI_COMMIT=26545cc2dd95bc3d27f056016300673bdeee78f5
ARG VHS_COMMIT=115de7a9d9e34410cffb9ecfd268e993b11a50fb

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

RUN set -eu; \
    mkdir -p /ComfyUI/models/text_encoders /ComfyUI/models/vae /ComfyUI/models/diffusion_models /ComfyUI/models/loras; \
    wget -q https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors -O /ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors & pid_text=$!; \
    wget -q https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors -O /ComfyUI/models/vae/wan_2.1_vae.safetensors & pid_vae=$!; \
    wget -q https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors -O /ComfyUI/models/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors & pid_low=$!; \
    wget -q https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors -O /ComfyUI/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors & pid_lora_high=$!; \
    wget -q https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors -O /ComfyUI/models/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors & pid_lora_low=$!; \
    wget -q https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors -O /ComfyUI/models/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors & pid_high=$!; \
    wait "$pid_text"; \
    wait "$pid_vae"; \
    wait "$pid_low"; \
    wait "$pid_lora_high"; \
    wait "$pid_lora_low"; \
    wait "$pid_high"
RUN mkdir -p /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife && \
    wget -q https://huggingface.co/hfmaster/models-moved/resolve/cab6dcee2fbb05e190dbb8f536fbdaa489031a14/rife/rife49.pth -O /ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation/ckpts/rife/rife49.pth

COPY . .
RUN mkdir -p /ComfyUI/user/default/ComfyUI-Manager
COPY config.ini /ComfyUI/user/default/ComfyUI-Manager/config.ini
COPY extra_model_paths.yaml /ComfyUI/extra_model_paths.yaml
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
