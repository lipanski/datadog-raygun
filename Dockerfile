FROM crystallang/crystal:0.24.2

ADD shard.yml /src/
ADD shard.lock /src/
WORKDIR /src
RUN crystal deps

ADD src /src
RUN crystal build --release datadog_raygun.cr

CMD ./datadog_raygun
