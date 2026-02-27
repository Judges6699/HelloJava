docker build -t javasec:latest . && docker run -d -p 80:8888 -v logs:/logs javasec
