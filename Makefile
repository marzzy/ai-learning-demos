# ---- Config ----
COMPOSE ?= docker-compose.yml
IMAGE   ?= $(shell grep -E '^IMAGE=' .env | cut -d= -f2)
SERVICE ?= $(shell grep -E '^SERVICE=' .env | cut -d= -f2)
ARCH    ?= aarch64              # Apple Silicon
CPUS    ?= 6
MEM     ?= 12                   # GB

# Models baked in your Dockerfile
CHAT_MODEL ?= llama3.1
ML_MODEL   ?= qwen2.5:7b-instruct

# Local API endpoint (OpenAI-compatible)
BASE_URL ?= http://localhost:11434

# ---- Colima lifecycle ----
.PHONY: colima-start colima-stop
colima-start:
	colima start --arch $(ARCH) --cpu $(CPUS) --memory $(MEM) --vz

colima-stop:
	colima stop

# ---- Compose lifecycle ----
.PHONY: ensure-image up down build up-build rebuild restart logs ps shell clean nuke

# Build only if the image is missing
ensure-image:
	@if [ -z "$$(docker images -q $(IMAGE))" ]; then \
		echo "🧱 Image $(IMAGE) not found → building..."; \
		docker compose -f $(COMPOSE) build; \
	else \
		echo "✅ Image $(IMAGE) exists → skipping build."; \
	fi

up:
	docker compose -f $(COMPOSE) up -d

down:
	docker compose -f $(COMPOSE) down

build:
	docker compose -f $(COMPOSE) build

# Ensure image, then up (no rebuild if present)
up-build: ensure-image up --no-build

# Force rebuild (ignore cache), then start
rebuild:
	$(MAKE) build --no-cache
	$(MAKE) up

restart:
	$(MAKE) down
	$(MAKE) up --no-build

logs:
	docker compose -f $(COMPOSE) logs -f $(SERVICE)

ps:
	docker compose -f $(COMPOSE) ps

shell:
	docker exec -it $(SERVICE) bash

# Remove containers, networks, and (optionally) images
clean:
	docker compose -f $(COMPOSE) down -v

# ⚠️ Nuke all dangling images (optional heavy clean)
nuke:
	docker system prune -af --volumes

# ---- Quick tests ----
.PHONY: test-gen test-chat test-ml health
# Low-level Ollama generate endpoint (non-OpenAI)
test-gen:
	curl -s $(BASE_URL)/api/generate -d '{ "model": "$(CHAT_MODEL)", "prompt": "Say hi in pirate style." }' | sed -E 's/\\n/\n/g'

# OpenAI-compatible Chat Completions (chat model)
test-chat:
	curl -s -X POST "$(BASE_URL)/v1/chat/completions" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer local" \
		-d '{ "model":"$(CHAT_MODEL)", "messages":[{"role":"user","content":"One sentence on running LLMs locally with Docker + Colima."}] }' \
	| sed -n 's/.*"content":"\([^"]*\)".*/\1/p'

# OpenAI-compatible Chat Completions (multilingual model)
test-ml:
	curl -s -X POST "$(BASE_URL)/v1/chat/completions" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer local" \
		-d '{ "model":"$(ML_MODEL)", "messages":[{"role":"user","content":"Traduce al alemán: «Estoy probando un LLM local con Docker.»"}] }' \
	| sed -n 's/.*"content":"\([^"]*\)".*/\1/p'

# Simple health check
health:
	curl -s $(BASE_URL)/api/tags | head -c 200 && echo
