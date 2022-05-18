FROM ghcr.io/renderinc/heroku-app-builder:heroku-20 AS builder

# The FROM statement above triggers the following steps
# 1. Copy the contents of the directory containing this Dockerfile to a Docker image
# 2. Detect the language
# 3. Build the app using the appropriate Heroku buildpack. All Heroku's official buildpacks are supported.

# For running the app, we use a clean base image and also one without Ubuntu development packages
# https://devcenter.heroku.com/articles/heroku-20-stack#heroku-20-docker-image
FROM ghcr.io/renderinc/heroku-app-runner:heroku-20 AS runner

# Copy build artifacts to runtime image
COPY --from=builder --chown=1000:1000 /render /render/
COPY --from=builder --chown=1000:1000 /app /app/

# Switch to non-root user
USER 1000:1000
WORKDIR /app

# Source all /app/.profile.d/*.sh files before process start.
# These are created by buildpacks.
# https://devcenter.heroku.com/articles/buildpack-api#profile-d-scripts
ENTRYPOINT [ "/render/setup-env" ]

# 4. By default, run the 'web' process type defined in the app's Procfile
# You may override the process type that is run by replacing 'web' with another
# process type name in the CMD line below. That process type must have been
# defined in the app's Procfile during build.
CMD [ "/render/process/web" ]