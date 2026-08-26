FROM registry.runpod.net/csmahori-generate-video-ksampler-dockerfile:48e898e6d

WORKDIR /

# Reuse the already-built image and replace only the small diagnostic handler.
COPY handler.py /handler.py

CMD ["/entrypoint.sh"]
