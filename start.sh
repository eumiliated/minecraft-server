#!/bin/bash
# Start Minecraft in background
java -Xmx400m -Xms400m -jar server.jar nogui &

# Install Playit if not present
if [ ! -f playit ]; then
  curl -L https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64 -o playit
  chmod +x playit
fi

# Run Playit tunnel (this stays in foreground so dyno stays alive)
./playit