# Taken from https://manas.tech/blog/2016/09/28/running-crystal-on-docker.html
FROM crystallang/crystal:0.24.2

ADD shard.yml /src/
ADD shard.lock /src/
WORKDIR /src
RUN crystal deps

ADD src /src
RUN crystal build --release datadog_raygun.cr

EXPOSE 80
CMD ./datadog_raygun --port 80
