docker buildx build -t sysbench:dev --platform=linux/amd64 --progress=plain --load .
docker run --rm sysbench:dev
