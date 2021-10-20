FROM eqalpha/keydb

# Copyright 2014-2021 Johan Andersson

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -yqq \
      net-tools supervisor gettext-base && \
    apt-get clean -yqq

RUN mkdir /keydb-conf && mkdir /keydb-data

COPY keydb-cluster.tmpl /keydb-conf/keydb-cluster.tmpl
COPY keydb.tmpl         /keydb-conf/keydb.tmpl

# Add startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Add script that generates supervisor conf file based on environment variables
COPY generate-supervisor-conf.sh /generate-supervisor-conf.sh

RUN chmod 755 /docker-entrypoint.sh

EXPOSE 7000 7001 7002 7003 7004 7005 7006 7007 5000 5001 5002

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["keydb-cluster"]
