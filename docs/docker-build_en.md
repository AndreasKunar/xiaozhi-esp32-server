# Building Docker Images Locally

Now that this project already includes GitHub‑automated Docker image compilation, this documentation is provided for users who need to compile Docker images locally.

1. **Install Docker**  

   ```bash
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

2. **Build Docker Images**  

   ```bash
   # Enter the project root directory
   # Build the server image
   docker build -t xiaozhi-esp32-server:server_latest -f ./Dockerfile-server .

   # Build the web image
   docker build -t xiaozhi-esp32-server:web_latest -f ./Dockerfile-web .
   ```

   After the build completes, you can start the project using Docker Compose.  
   
   Adjust the image versions in `docker-compose.yml` to the ones you just built  

   ```bash
   cd main/xiaozhi-server
   docker compose up -d
   ```

---

### Notes

- The commands inside the fenced code blocks remain unchanged, as they are the actual shell commands.
- Only the surrounding explanatory text has been translated into English.
