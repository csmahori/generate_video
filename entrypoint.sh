#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Start ComfyUI in the background
# --cache-none (2026-09-02, stage2 OOM fix): disables ComfyUI's node-output
# caching entirely, at the cost of re-executing every node on each run
# instead of reusing cached results. This is the platform-documented fix for
# the stage2 host-RAM OOM we diagnosed (node outputs -- including from
# custom nodes like the RIFE interpolation and ESRGAN upscale nodes this
# pipeline uses -- accumulating in host RAM across sequential batched
# executions within the same long-running ComfyUI process). The handler's
# own free_comfy_memory() /free call after each stage2 batch stays in place
# as a harmless extra safety net, but --cache-none is the real fix since
# /free is not guaranteed to fully clear custom-node caches.
echo "Starting ComfyUI in the background..."
python /ComfyUI/main.py --listen --use-sage-attention --cache-none &

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
max_wait=120  # 최대 2분 대기
wait_count=0
while [ $wait_count -lt $max_wait ]; do
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    echo "Waiting for ComfyUI... ($wait_count/$max_wait)"
    sleep 2
    wait_count=$((wait_count + 2))
done

if [ $wait_count -ge $max_wait ]; then
    echo "Error: ComfyUI failed to start within $max_wait seconds"
    exit 1
fi

# Start the handler in the foreground
# 이 스크립트가 컨테이너의 메인 프로세스가 됩니다.
echo "Starting the handler..."
exec python handler.py