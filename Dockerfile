FROM docker/sandbox-templates:opencode
USER root

RUN apt-get update -qq \
    && apt-get purge -y --auto-remove unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER agent

RUN npm install -g @kilocode/cli

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
#RUN chmod +x /usr/local/bin/entrypoint.sh


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["kilo"]
