ARG BASE_IMAGE=adoptopenjdk:8-hotspot
FROM $BASE_IMAGE

ENV RUN_USER                                        jira
ENV RUN_GROUP                                       jira
ENV RUN_UID                                         2001
ENV RUN_GID                                         2001

# https://confluence.atlassian.com/display/JSERVERM/Important+directories+and+files
ENV JIRA_HOME                                       /var/atlassian/application-data/jira
ENV JIRA_INSTALL_DIR                                /opt/atlassian/jira

WORKDIR $JIRA_HOME

# Expose HTTP port
EXPOSE 8080

CMD ["/entrypoint.py"]
ENTRYPOINT ["/tini", "--"]

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends fontconfig python3 python3-jinja2 \
    && apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ARG JIRA_SOFTWARE_VERSION=8.11.0
ARG JIRA_SOFTWARE_DOWNLOAD_URL=https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-${JIRA_SOFTWARE_VERSION}.tar.gz
ARG JIRA_SERVICEDESK_VERSION=4.11.0
ARG JIRA_SERVICEDESK_DOWNLOAD_URL=https://product-downloads.atlassian.com/software/jira/downloads/atlassian-servicedesk-${JIRA_SERVICEDESK_VERSION}.tar.gz

RUN groupadd --gid ${RUN_GID} ${RUN_GROUP} \
    && useradd --uid ${RUN_UID} --gid ${RUN_GID} --home-dir ${JIRA_HOME} --shell /bin/bash ${RUN_USER} \
    && echo PATH=$PATH > /etc/environment \
    \
    && mkdir -p                                     ${JIRA_INSTALL_DIR} \
    && curl -L --silent                             ${JIRA_SERVICEDESK_DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${JIRA_INSTALL_DIR}" \
    && curl -L --silent                             ${JIRA_SOFTWARE_DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${JIRA_INSTALL_DIR}" \
    && chmod -R "u=rwX,g=rX,o=rX"                   ${JIRA_INSTALL_DIR}/ \
    && chown -R root.                               ${JIRA_INSTALL_DIR}/ \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/logs \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/temp \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_INSTALL_DIR}/work \
    \
    && sed -i -e 's/^JVM_SUPPORT_RECOMMENDED_ARGS=""$/: \${JVM_SUPPORT_RECOMMENDED_ARGS:=""}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/^JVM_\(.*\)_MEMORY="\(.*\)"$/: \${JVM_\1_MEMORY:=\2}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/-XX:ReservedCodeCacheSize=\([0-9]\+[kmg]\)/-XX:ReservedCodeCacheSize=${JVM_RESERVED_CODE_CACHE_SIZE:=\1}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    \
    && touch /etc/container_id \
    && chown ${RUN_USER}:${RUN_GROUP}               /etc/container_id \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${JIRA_HOME}

VOLUME ["${JIRA_HOME}"] # Must be declared after setting perms

COPY entrypoint.py \
     shared-components/image/entrypoint_helpers.py  /
COPY shared-components/support                      /opt/atlassian/support
COPY config/*                                       /opt/atlassian/etc/
