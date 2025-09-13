#!/bin/sh

# Accept the Minecraft EULA
echo "eula=true" > eula.txt

# Start Minecraft server in the background
java -Xmx1024M -Xms1024M -jar server.jar nogui &

# Start Playit tunnel (foreground so dyno stays alive)
./playit