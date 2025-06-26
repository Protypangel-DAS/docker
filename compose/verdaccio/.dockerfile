FROM verdaccio/verdaccio:latest
USER root

ENV AUTH_GITLAB_PACKAGE=verdaccio-gitlab-auth

# -------- Plugin -------------------------------------------------------------
COPY /plugins/auth-gitlab /verdaccio/plugins/$AUTH_GITLAB_PACKAGE
RUN npm install --omit=dev --prefix /verdaccio/plugins/$AUTH_GITLAB_PACKAGE
RUN chown -R $VERDACCIO_USER_UID:root /verdaccio/plugins

# -------- Configuration ------------------------------------------------------
COPY config.yaml /verdaccio/conf/config.yaml
RUN chown $VERDACCIO_USER_UID:root /verdaccio/conf/config.yaml

# -------- Retour à l’image officielle ---------------------------------------
USER $VERDACCIO_USER_UID
# (WORKDIR et CMD d’origine sont conservés)
