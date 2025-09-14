#!/usr/bin/env bash
set -euo pipefail

# --- config (set these as Heroku config vars) ---
: "${NGROK_AUTHTOKEN:?set NGROK_AUTHTOKEN in Heroku config}"
JAVA_MEM="${JAVA_MEMORY:-512M}"   # tune this (e.g. 1024M)
SERVER_JAR="${SERVER_JAR:-server.jar}"  # either in repo or downloaded
PAPER_DOWNLOAD_URL="${PAPER_DOWNLOAD_URL:-}" # optional

# --- helper: download paper if not present ---
if [ ! -f "$SERVER_JAR" ] && [ -n "$PAPER_DOWNLOAD_URL" ]; then
  echo "Downloading server jar..."
  curl -sSL "$PAPER_DOWNLOAD_URL" -o "$SERVER_JAR"
fi

# accept EULA (required)
echo "eula=true" > eula.txt

# --- download ngrok binary if missing (Linux x86_64) ---
if [ ! -x ./ngrok ]; then
  echo "Retrieving ngrok..."
  curl -sSL "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip" -o ngrok.zip
  unzip -q ngrok.zip
  chmod +x ngrok
  rm ngrok.zip
fi

# register ngrok token (only needs to run once per dyno boot)
./ngrok authtoken "$NGROK_AUTHTOKEN" || true

# start ngrok TCP tunnel to local 25565 in background
./ngrok tcp 25565 --log=stdout > ngrok.log 2>&1 &
NGROK_PID=$!

# trap to stop server gracefully on SIGTERM (Heroku sends SIGTERM before shutdown)
_term() {
  echo "SIGTERM received: shutting down Minecraft server..."
  # Attempt graceful stop by sending SIGINT to JVM
  if [ ! -z "${MC_PID:-}" ]; then
    kill -SIGINT "$MC_PID" || true
    wait "$MC_PID"
  fi
  # let ngrok exit
  kill -TERM "$NGROK_PID" 2>/dev/null || true
  exit 0
}
trap _term SIGTERM

# start Minecraft server in foreground so trap can catch it
java -Xmx"$JAVA_MEM" -jar "$SERVER_JAR" nogui &
MC_PID=$!
wait "$MC_PID"
