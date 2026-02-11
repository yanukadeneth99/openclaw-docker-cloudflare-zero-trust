# tailscale-setup/Dockerfile
FROM node:22-bookworm

# 1. Install system prerequisites
RUN apt-get update && \
    apt-get install -y build-essential curl file git golang-go ffmpeg sudo ca-certificates gnupg
RUN apt-get install -y jq

# 2. Install Tailscale
RUN mkdir -p --mode=0755 /usr/share/keyrings && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale
RUN apt-get install -y jq

# 3. Create a 'linuxbrew' user setup
RUN mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R node:node /home/linuxbrew/.linuxbrew

# 4. Switch to 'node' user for Brew
USER node
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

# 5. Install tools via Brew
RUN brew install uv gh

# Switch back to root for setup
USER root

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable

WORKDIR /app

# Copy wrapper script
COPY start-with-tailscale.sh /app/start-with-tailscale.sh
RUN chmod +x /app/start-with-tailscale.sh

# Install Dependencies (Cached)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install --frozen-lockfile

# Build
COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production
ENV TAILSCALE_DIR=/home/node/.tailscale

# Run as non-root (Tailscale userspace works as user)
USER node
RUN mkdir -p /home/node/.tailscale

# Entrypoint wrapper
ENTRYPOINT ["/app/start-with-tailscale.sh"]
CMD ["node", "dist/index.js", "gateway", "--port", "59765", "--allow-unconfigured"]
