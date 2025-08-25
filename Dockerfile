# Custom Ollama image with models pre-pulled
FROM ollama/ollama:latest

# Pull models during build so they’re layered into the image.
# We start the server briefly, pull, then stop it.
RUN bash -lc "\
  (ollama serve & sleep 3) && \
  ollama pull llama3.1 && \
  ollama pull qwen2.5:7b-instruct && \
  pkill ollama || true \
"
