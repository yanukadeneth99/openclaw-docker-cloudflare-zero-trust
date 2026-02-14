# 🦞 OpenClaw - Docker + Cloudflare Zero Trust & Tailscale

This is a specialized fork of **OpenClaw** designed for secure, robust deployment using **Docker**, **Cloudflare Zero Trust**, and **Tailscale**.

## Introduction

**OpenClaw** is your personal AI assistant that runs on your own devices. This fork enhances the standard OpenClaw deployment by integrating:

- **Cloudflare Zero Trust**: Expose your OpenClaw instance securely to the public internet without opening ports on your firewall, protected by Cloudflare's massive edge network.
- **Tailscale**: A private, encrypted mesh VPN that allows you to connect your other devices (nodes) to your OpenClaw Gateway securely, as if they were on the same local network, regardless of where they are physically located.

## Why use this fork?

Unlike the standard setup which might require exposing ports (`59765`) directly or managing complex Nginx reverse proxies with SSL certificates manually, this setup:

1.  **Zero Open Ports**: No need to open inbound ports on your router or VPS firewall.
2.  **Double Layer Security**: access your instance publicly via Cloudflare (with optional Access policies) or privately via Tailscale.
3.  **Seamless Node Networking**: Connect remote agents (iOS, Android, macOS) via Tailscale without complex routing.
4.  **Production Ready**: encapsulated in Docker containers for consistency and stability.

## Requirements

To run this project, you will need:

- A Linux server (VPS) or a machine capable of running Docker.
- **Docker** and **Docker Compose** installed.
- A **Cloudflare Account** with a domain name configured.
- A **Tailscale Account**.
- Basic familiarity with CLI.

---

## Step 1: Setup Cloudflare Zero Trust

1.  Log in to the [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/).
2.  Navigate to **Networks > Tunnels**.
3.  Click **Create a Tunnel**.
4.  Choose **Cloudflared** as the connector type.
5.  Name your tunnel (e.g., `openclaw-server`) and save.
6.  You will see a token/install command. **Copy the Tunnel Token**. You will need this for the `.env` file later.
7.  Click **Next** to configure the **Public Hostname**.
    - **Subdomain**: `claw` (or whatever you prefer).
    - **Domain**: Select your domain.
    - **Path**: Leave empty.
    - **Service**: `HTTP` -> `openclaw-gateway:59765`.
      _Note: We use `openclaw-gateway` as the hostname because that is the service name in our `docker-compose.yml`._
8.  Save the tunnel.

## Step 2: Setup Docker & Run Project on Linux

### 1. Install Docker

If you haven't installed Docker yet:

```bash
curl -fsSL https://get.docker.com | sh
```

### 2. Clone the Repository

```bash
git clone https://github.com/yanukadeneth99/openclaw-docker-cloudflare-zero-trust.git
cd openclaw-docker-cloudflare-zero-trust
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
nano .env
```

Define the following variables:

```env
# Cloudflare Tunnel Token (from Step 1)
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...

# Tailscale Auth Key (Create one at https://login.tailscale.com/admin/settings/keys)
# Make sure to tag it if using ACLs, or make it reusable/ephemeral as needed.
TS_AUTHKEY=tskey-auth-...

# Your OpenClaw Gateway Token (Generate a random secure string)
OPENCLAW_GATEWAY_TOKEN=your-secure-token-here

# Optional: Other integrations
GITHUB_TOKEN=...
OPENAI_API_KEY=...
ANTHROPIC_API_KEY=...
```

### 4. Run with Docker Compose

Start the services in detached mode:

```bash
docker compose up -d
```

This will start two containers:

- `openclaw-core`: The OpenClaw Gateway (with Tailscale).
- `openclaw-tunnel`: The Cloudflare Tunnel daemon.

## How to Run & Work with OpenClaw

### Accessing the Interface

Once running, your OpenClaw instance is accessible at:

- **Public URL**: `https://claw.yourdomain.com` (configured in Cloudflare).
- **Tailscale Address**: Use the Tailscale IP or MagicDNS hostname (e.g., `http://openclaw-vps:59765`) if you are connected to the same Tailnet.

### Checking Logs

To see what the gateway is doing or to troubleshoot:

```bash
docker compose logs -f openclaw-gateway
```

### Executing Commands

To run OpenClaw CLI commands inside the container:

```bash
docker exec -it openclaw-core node dist/index.js doctor
```

---

## Onboarding & Initial Setup

After the containers are running, you need to configure your OpenClaw instance. This involves creating an admin user and setting up your LLM providers (Anthropic, OpenAI, etc.).

Run the onboarding wizard inside the container:

```bash
docker exec -it openclaw-core node dist/index.js onboard
```

Follow the interactive prompts in your terminal. This wizard will guide you through the initial setup securely. All configuration is saved to the persistent `data/` volume.

---

## Connecting Another Agent via Tailscale

You can connect other OpenClaw nodes (like the macOS app or another CLI agent) to this gateway securely over Tailscale.

1.  **Install Tailscale** on your client device (Mac, iPhone, etc.) and log in to the same Tailscale account.
2.  **Configure the Client**:
    - Point your client (App or CLI) to the **Tailscale IP address** of the Docker container (or the mapped MagicDNS name).
    - Example Gateway URL: `ws://openclaw-vps:59765` (or `ws://100.x.y.z:59765`).
    - Enter the `OPENCLAW_GATEWAY_TOKEN` you defined in your `.env` file.
3.  **Approve the Connection**:
    - When a new device connects, it may need approval depending on your security settings (though providing the correct token usually authorizes it).
    - If a node requires explicit approval (e.g. `dmPolicy="pairing"`), check the logs for a pairing code.
    - To list all pending connection requests:

    ```bash
    docker exec -it openclaw-core node dist/index.js pairing list
    ```

    - Run the approval command inside the docker container:

    ```bash
    docker exec -it openclaw-core node dist/index.js pairing approve <NODE_ID_OR_CHANNEL> <CODE>
    ```

## Practical Use Cases

This setup empowers you to use OpenClaw in your daily life securely and effectively:

- **Unified AI Inbox**: Connect WhatsApp, Telegram, Discord, and Slack to one central brain. Message it from any platform and maintain a single continuous context.
- **Private Assistant on Any Device**: Access your personal AI from your phone (via Tailscale or Cloudflare) without exposing it to the public web.
- **Secure Automation**: Let the AI run tasks or scripts on your server (via the `exec` tool) while you are away, authorized securely through the tunnel.
- **Development Companion**: Keep a persistent coding session alive on your server and access it from VS Code or a browser on any machine.
- **Voice Interface**: Connect the iOS/Android app to talk to your agent while driving or walking, properly secured behind your private VPN.

## Links and Support

- **Original Project**: [OpenClaw on GitHub](https://github.com/openclaw/openclaw)
- **Documentation**: [OpenClaw Docs](https://docs.openclaw.ai)
- **Cloudflare Zero Trust**: [Overview](https://www.cloudflare.com/products/zero-trust/)
- **Tailscale**: [Getting Started](https://tailscale.com/kb/1017/install)

For support with this specific Docker setup, please open an issue in this repository. For general OpenClaw questions, join the [OpenClaw Discord](https://discord.gg/clawd).
