# Local LLM Dev (Docker + Colima + Ollama)

This project runs **chat + multilingual LLMs** locally using [Ollama](https://ollama.ai/) inside Docker with Colima.  
Models (`llama3.1`, `qwen2.5:7b-instruct`) are **baked into the image** so you don’t need to pull them every time.

---

## 🚀 Requirements

- [Homebrew](https://brew.sh/)  
- [Colima](https://github.com/abiosoft/colima)  
- [Docker](https://www.docker.com/) (CLI is enough)  
- `make`
= `.env` → sets the image tag and service name used by Docker Compose + Makefile

Install on macOS:

```bash
brew install colima docker docker-compose make
````

---

## ⚙️ How It Works

- **Dockerfile** → builds a custom Ollama image and pulls the models at **build time**
- **docker-compose.yml** → defines the `ollama` service with a fixed image name
- **Makefile** → provides shortcuts for Colima + Compose lifecycle

The Ollama server exposes an **OpenAI-compatible API** at:

```
http://localhost:11434/v1
```

---

## 📦 Common Commands

Start Colima VM (once per reboot):

```bash
make colima-start
```

Build the image (only if missing) and start the container:

```bash
make up-build
```

Stop everything:

```bash
make down && make colima-stop
```

Force rebuild (e.g. after editing Dockerfile or models):

```bash
make rebuild
```

Show logs:

```bash
make logs
```

Open a shell in the container:

```bash
make shell
```

---

## ✅ Quick Tests

Chat model (`llama3.1`):

```bash
make test-chat
```

Multilingual model (`qwen2.5:7b-instruct`):

```bash
make test-ml
```

Low-level health check:

```bash
make health
```

---

## 🔑 Usage in Code

Set environment variables and use any OpenAI client SDK:

```bash
export OPENAI_BASE_URL=http://localhost:11434/v1
export OPENAI_API_KEY=local
```

### Node.js Example

```ts
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: process.env.OPENAI_BASE_URL,
  apiKey: process.env.OPENAI_API_KEY,
});

const resp = await client.chat.completions.create({
  model: "llama3.1",
  messages: [{ role: "user", content: "Hello from Node + local Ollama!" }],
});
console.log(resp.choices[0].message.content);
```

---

## 📝 Notes

- Models are baked into the Docker image → containers start instantly, no runtime pulls
- `make up-build` builds only once and reuses the image afterward
- `make rebuild` forces a fresh build ignoring cache
- Apple Silicon users: Compose is set to use `linux/arm64` (fast on M1/M2)
