FROM registry.runpod.net/wlsdml1114-generate-video-ksampler-dockerfile:a9247705c

WORKDIR /

# Keep the exact ComfyUI, custom nodes, workflows, and model files from the
# image that successfully rendered our 1280x720 test. Replace only the
# serverless response handler so the MP4 is uploaded to R2.
COPY handler.py /handler.py

CMD ["/entrypoint.sh"]
