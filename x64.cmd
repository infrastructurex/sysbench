docker buildx build -t sysbench:dev --platform=linux/amd64 --progress=plain --load .
docker run --rm -it -p 8080:8080 -e TIME=10 -e SIZE=10G sysbench:dev
