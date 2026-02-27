docker build -t javasec:latest . && docker run -d --name javasec -p 80:8888 -v logs:/logs javasec:latest
