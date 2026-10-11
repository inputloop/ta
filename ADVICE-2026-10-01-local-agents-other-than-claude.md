# ADVICE · 2026-10-01 · Setting up local (and free) agents other than Claude

Written by Claude (Sonnet 5.5) for Corwin and Bryant, from two research passes read on 2026-10-01 (web pages, each cited below). It answers: *"How do I set up local agents other than Claude?"*, covering what you mentioned (Gemini, GPT/Copilot, a Sonnet-class second witness, a free local model, Haiku) and anything else free to try.

**How to read this.** *Observed* means a page said it, as read on 2026-10-01; the fetch tool summarizes pages, so check numbers on the cited page before you rely on them. *My view* is my own judgement. Anything I could not confirm is listed at the end, and marked **(unverified)** where it appears. Prices, limits and free tiers in this area change quickly; this is a snapshot.

---

## The short answer

1. **Do this first (free, local, open source): Ollama + OpenCode.** Ollama runs an open-weight model on your own PC; OpenCode is an open-source agent (MIT) that talks to it. Nothing leaves your machine if you pick only local models. Section 2A.
2. **Then use the Copilot seat you just activated.** It is the quickest way to get a hosted GPT-family agent with no new bill, and it reads the same rules files as the others. It is proprietary software, and your organization's policy must allow its command-line tool. Section 2B.
3. **For Gemini:** the free route you may remember has changed (Section 2C).
4. **From Emacs:** `gptel` or `ellama` talk to the same local model; `agent-shell` talks to several agents. Section 3.
5. **Testing our agent model on them** (the second-witness idea from the recording) has its own short protocol in Section 5. Use the same rules file on each.

---

## 1. What you mentioned, mapped to options

| You said | What it maps to here | Free? |
|---|---|---|
| Gemini | Antigravity CLI (Google's new tool, proprietary), or the Gemini API in code | free plan exists; limits not published (Section 2C) |
| Enterprise GPT or Copilot | GitHub Copilot CLI on your seat | covered by the seat; org policy applies (2B) |
| A Sonnet-level second witness | a strong open-weight model run locally (Qwen, Gemma, gpt-oss families) needs a big GPU; otherwise Copilot's hosted models | local: free; hosted: seat |
| Haiku-level / "less sophisticated" models | a small local model (4B–8B) | free |
| A free local model on your machine | Ollama or llama.cpp plus any open agent | free |

---

## 2. Setup paths

### 2A. Free and local: Ollama + an open-source agent

**Check your hardware first.** In PowerShell: `nvidia-smi` (NVIDIA GPU and memory), `Get-CimInstance Win32_VideoController | Select Name,AdapterRAM`, and `systeminfo | findstr /C:"Total Physical Memory"`. Install on **Windows itself**, not inside a Linux VM, so the GPU is used.

**Which model fits** (my view, from model cards read on 2026-10-01; I found no independent agent benchmark, so treat this as a starting point):

| Your hardware | Try first | Why |
|---|---|---|
| CPU only, 16 GB RAM | Gemma 4 E4B, or a Qwen3 4B–8B model | small enough to run; slow and weak at multi-step tool use, which makes it a good "weak witness" |
| 8 GB GPU | Gemma 4 E4B or 12B, or Qwen3 8B (5.2 GB) | fits in video memory |
| 24 GB GPU | gpt-oss:20b, Gemma 4 26B or 31B, Qwen3.8-27B | the closest local stand-in for a mid-size hosted model |

*Observed licenses:* gpt-oss is Apache-2.0 (ollama.com/library/gpt-oss); Qwen3.8-27B is Apache-2.0 (huggingface.co/Qwen/Qwen3.8-27B); Google's page states Gemma 4 is Apache-2.0 (ai.google.dev/gemma/docs/gemma_4_license). Llama and Mistral-large licenses I did not confirm: read them first.

**Install Ollama (MIT, version 0.35.0 dated 2026-09-28 per its releases page).**
1. Download the installer from ollama.com, or in PowerShell `winget install Ollama.Ollama` **(unverified package name)**.
2. `ollama pull gpt-oss:20b` (or a smaller model from the table).
3. `ollama run gpt-oss:20b` for a first chat.
4. `curl http://localhost:11434/v1/models` to confirm the local address that agents will use.

**Warning that bites everyone.** Ollama's default context window is small (Aider's docs say 2,000 tokens) and it silently drops what does not fit. A long rules file can be cut off without any message, which would make a weak model look worse than it is. Set the context explicitly (for example 32768) before judging any result.

**Install OpenCode (MIT; opencode.ai/docs).**
1. On Windows the docs recommend WSL. In a WSL shell: `curl -fsSL https://opencode.ai/install | bash` (it is also on npm, Chocolatey and Scoop).
2. Add your local model by editing `opencode.json`: a provider using `@ai-sdk/openai-compatible` with `baseURL` set to `http://localhost:11434/v1` and a `models` entry (docs: opencode.ai/docs/providers).
3. Run `opencode` in a project folder, then `/models` to pick it, and `/init` to write an `AGENTS.md`.
4. WSL reaching Ollama on Windows may need the Windows host address instead of `localhost` **(unverified)**.

**Other open-source agents that work the same way** (all can point at the local address above):
- **Aider** (Apache-2.0): `python -m pip install aider-install`, then `aider-install`; run `aider --model ollama_chat/<name>` with `OLLAMA_API_BASE=http://127.0.0.1:11434`. Rules: `aider --read CONVENTIONS.md`. Caution: the latest release the research found was dated 2025-08-09, which looks stale; check the project's releases page before relying on it.
- **Goose** (Apache-2.0, now under the Linux Foundation): `goose configure`, then `goose session`; reads `.goosehints` and `AGENTS.md`; extensions via MCP. On WSL you may need to export API keys by hand to avoid a keyring error.
- **Cline** (Apache-2.0): editor plug-in and command line; reads `.clinerules`; works with Ollama and LM Studio. No hosted free tier found.
- **Continue**: Apache-2.0, but its repository is read-only and not actively maintained; not worth building on.
- **Qwen Code**: described as open source; I did not verify a license text. A third-party article says its free hosted login ended 2026-04-15, so use it with a local model.

**Other runtimes (instead of Ollama):**
- **llama.cpp** (`llama-server`, license believed MIT, **unverified**): the engine many tools wrap. Release b10456 dated 2026-08-17 has Windows builds for CPU, CUDA, Vulkan and others. Start it with `llama-server -hf <repo>:<quant> --jinja -ngl 99 -c 32768 --port 8080`. Without `--jinja`, tool calls may not parse. Its tool and MCP features come with a warning not to enable them in untrusted environments.
- **Jan** (Apache-2.0): desktop chat app, offline-capable, local server on `localhost:1337`, MCP supported. It can also call cloud providers, so do not enter cloud keys for a local-only test.
- **Open WebUI**: a browser front end for Ollama or any compatible address. The research found its license is "multiple licenses" with newer code under its own license; I believe it adds a branding clause, which is not OSI-clean, but verify the LICENSE file before depending on it.
- **LM Studio**: easy to use, with a command-line mode and MCP, but **proprietary**; its terms grant personal and internal use. Fine as a convenience or a comparison, not as part of a software-freedom stack.

**Keeping it local.** Ollama's compatibility page also shows a cloud address (`https://ollama.com/v1`), and LM Studio advertises cloud models. Use only locally downloaded model names. I found no official statement of these runtimes' telemetry defaults, so check actual traffic (a Windows firewall rule or a packet capture) if "nothing leaves the machine" matters.

### 2B. Your Copilot seat (hosted GPT-family agent)

- **What it is:** GitHub Copilot's command-line agent. Its license forbids modification and standalone redistribution, so it is **not** open source (its LICENSE.md). It is the right tool when you want to test on a hosted model without a new bill.
- **Install:** `winget install GitHub.Copilot`, or `npm install -g @github/copilot` (Node 22 or newer), or in WSL `curl -fsSL https://gh.io/copilot-install | bash` (docs.github.com, install-copilot-cli).
- **First run:** `copilot`, then `/login` (or set `COPILOT_GITHUB_TOKEN` to a fine-grained token with the "Copilot Requests" permission), then `/model` to choose a model.
- **Your enterprise seat:** the organization's policy for the command-line tool must be on, and organization owners also control agent mode, MCP servers and model availability; enterprise policy overrides organization policy (GitHub docs, read 2026-10-01). If `copilot` says you are not allowed, that policy is why; an owner has to switch it on.
- **Data:** the plans page says Business and Enterprise do not train on your data, while individual plans may, with opt-out. For an employer's seat, do not paste anything private or client-related.
- **Rules files it reads:** `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, and `~/.copilot/copilot-instructions.md`. They are merged with no priority order, so use one file only when testing.
- **Local models through it:** the docs show `COPILOT_PROVIDER_BASE_URL=http://localhost:11434`, `COPILOT_MODEL=<name>` and `COPILOT_OFFLINE=true`; models need tool calling and streaming. Whether a subscription is still needed for that is not stated.
- **Free personal plan:** Free allows 2,000 completions and 50 chat requests per month; "all plans include Copilot CLI" (GitHub plans page).

### 2C. Gemini, ChatGPT/Codex, Mistral and the rest

- **Gemini CLI.** Observed: Google ended free and personal-account access to Gemini CLI on 2026-06-18 and replaced it with the **Antigravity CLI** (`agy`), which is proprietary (Google developers blog; geminicli.com quota page). Antigravity has a $0 plan with Flash-class models and "basic rate restrictions"; I found no numeric limits and no stated data policy for it, so ask before you paste private material. Install per a third-party guide: Windows `irm https://antigravity.google/cli/install.ps1 | iex`; WSL `curl -fsSL https://antigravity.google/cli/install.sh | bash`. It needs a processor that exposes AES instructions, and some virtual machines do not, so it may fail in WSL or a VM with "Illegal instruction." The old open-source Gemini CLI (Apache-2.0) still exists as a repository, but I did not verify that it can reach a local model. The Gemini API's free tier uses your content to improve Google's products (its pricing page).
- **OpenAI Codex CLI** (Apache-2.0). Observed: the CLI is **not** on the ChatGPT Free plan; it needs a paid plan or an API key (OpenAI's pricing page). The free route is `codex --oss` against a local model, with `oss_provider = "ollama"` in `~/.codex/config.toml`. Install: `npm install -g @openai/codex`; on Windows the docs prefer the native sandbox with WSL as an alternative. It reads `AGENTS.md`.
- **Mistral Vibe CLI** (Apache-2.0): `pip install mistral-vibe` or `uv tool install mistral-vibe`, then `vibe --setup` with a key from console.mistral.ai. Two Mistral pages disagree about whether the free plan includes it, so test with your own account. Reads `AGENTS.md`; MCP via `/mcp add`.
- **OpenCode's free hosted models ("Zen").** Observed: nine free models, **some of which may use your prompts for training** (the docs name them); two are listed as zero-retention. Do not send private material to the free ones.
- **Microsoft Copilot (consumer).** I found no coding-agent route in it; the GitHub Copilot seat is the relevant Microsoft tool.

---

## 3. From Emacs

- **gptel** (GPL-3.0, MELPA and NonGNU ELPA): talks to Ollama, llama.cpp and 30+ providers, with tool use and MCP. Observed configuration:
  ```elisp
  (gptel-make-ollama "Ollama" :host "localhost:11434" :stream t :models '(gpt-oss:20b))
  (gptel-make-openai "llama-cpp" :stream t :protocol "http" :host "localhost:8080" :models '(test))
  ```
  To load a rules file as a named system prompt, I suggest the following, **which I have not tested**:
  ```elisp
  (setf (alist-get 'rules gptel-directives)
        (with-temp-buffer (insert-file-contents "~/rules.md") (buffer-string)))
  ```
  then choose it in `gptel-menu`.
- **ellama** (GPL-3.0, GNU ELPA): uses the `llm` package with Ollama and others; has plan-and-act loops, sub-agents, an optional data-loss guard and protection against irreversible actions.
- **agent-shell** (GPL-3.0, MELPA): runs agents that speak the ACP protocol (Gemini/Antigravity-era tools, Codex, Goose, Qwen Code, Mistral Vibe, OpenCode and others) inside Emacs: `(use-package agent-shell :ensure t)`.

---

## 4. Choosing, in plain words

| If you want | Use |
|---|---|
| Nothing leaves your machine, software-freedom stack | Ollama + OpenCode or Aider or Goose, from Windows |
| A hosted GPT-family witness at no new cost | Copilot CLI on your seat (proprietary, org policy) |
| A Gemini | Antigravity CLI free plan (proprietary; ask about data first) |
| A quick look from inside Emacs | gptel with the local address |
| A very weak witness on purpose | a 4B model on CPU |

---

## 5. Using them as second witnesses for our agent model

This follows the recording's second-witness idea (rec L049–L054). Keep it small.

1. **One rules file, same on every agent.** Put the agent model in `AGENTS.md` where the tool reads it (OpenCode, Codex, Goose, Mistral Vibe and Copilot all do); for Aider use `--read`; for gptel use the directive above. Do not let a tool read two copies (Copilot merges several files, so give it only one).
2. **Hold settings equal.** Same task script, same context size, same temperature where the tool lets you set it. Note reasoning-model output ("thinking" text) so it is not counted as the answer.
3. **Save every run** as a file with the model name, tool, version and date. Keep failures.
4. **Plants by someone other than the author.** Have a different agent or person put the faults in, as last session's result shows authors' own plants overstate a check (1 of 55 caught).
5. **Say NOT CHECKED when a witness could not run it** rather than guessing how it would behave.

---

## 6. Privacy and blast radius

- Local models never see anything unless a tool sends it on; verify with a firewall rule.
- Free hosted tiers often train on your prompts (Gemini API free tier, some OpenCode Zen models, individual Copilot plans). Do not send the private contact details that sit in some lab files.
- Your employer's Copilot seat is theirs; keep work and personal material apart.
- Agent tools can run commands and edit files. Start in a scratch folder, not in a lab folder, until you trust a setup.

---

## 7. What I could not confirm

- Winget package names for Ollama and llama.cpp; Ollama's Linux install script; Modelfile syntax for a built-in system prompt (the message route works regardless).
- Whether llama-server has a system-prompt-file flag in current builds (check `llama-server --help`).
- Open WebUI's exact license terms; Llama and Mistral model licenses; Qwen Code's license text.
- Numeric free limits for Antigravity and Mistral; Antigravity's free-plan data policy.
- MCP details for Aider, Cline, Qwen Code and Antigravity.
- Whether Copilot's local-model mode needs a paid subscription; whether an organization seat's terms allow third-party clients such as OpenCode.
- Any independent agent benchmark by hardware tier.
- That WSL can reach Ollama on the Windows host at `localhost`.

Each is a one-line check on the page or tool itself. If you tell me which to settle, I can read that page.

---

## Sources (read 2026-10-01)

- Ollama: https://github.com/ollama/ollama/releases · https://docs.ollama.com/api/openai-compatibility · https://docs.ollama.com/integrations · https://ollama.com/library/gpt-oss · https://ollama.com/library/gemma4
- llama.cpp: https://github.com/ggml-org/llama.cpp/releases · https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
- LM Studio: https://lmstudio.ai/ · https://lmstudio.ai/terms · https://lmstudio.ai/docs/developer · Jan: https://github.com/janhq/jan · Open WebUI: https://github.com/open-webui/open-webui
- Models: https://huggingface.co/Qwen/Qwen3.8-27B · https://ai.google.dev/gemma/docs/gemma_4_license
- Gemini/Antigravity: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/ · https://geminicli.com/docs/resources/quota-and-pricing/ · https://antigravity.google/pricing · https://ai.google.dev/gemini-api/docs/pricing
- Codex: https://github.com/openai/codex · https://learn.chatgpt.com/docs/pricing · https://learn.chatgpt.com/docs/config-file/config-advanced
- Copilot: https://github.com/features/copilot/plans · https://docs.github.com/en/copilot/get-started/plans · https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli · https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions · https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-byok-models · https://raw.githubusercontent.com/github/copilot-cli/main/LICENSE.md
- OpenCode: https://opencode.ai/docs/ · https://opencode.ai/docs/providers/ · https://opencode.ai/docs/zen/ · Aider: https://aider.chat/docs/llms/ollama.html · https://aider.chat/docs/usage/conventions.html · https://github.com/Aider-AI/aider/releases
- Goose: https://goose-docs.ai/docs/getting-started/installation · Cline: https://docs.cline.bot/getting-started/what-is-cline · Mistral: https://mistral.ai/pricing · https://github.com/mistralai/mistral-vibe
- Emacs: https://github.com/karthink/gptel · https://github.com/s-kostyaev/ellama · https://github.com/xenodium/agent-shell
