ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim as base

# Rack app lives here
WORKDIR /app

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN --mount=type=cache,id=prod-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=prod-apt-lib,sharing=locked,target=/var/lib/apt
RUN apt-get update -qq && \
    apt-get install -y libpq-dev \
    build-essential --no-install-recommends -y \
    postgresql-client
RUN apt-get install -y imagemagick libmagickwand-dev --no-install-recommends --fix-missing
RUN rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile* .
RUN bundle install

# Final stage for app image
FROM base

# Run and own the application files as a non-root user for security
RUN useradd ruby --home /app --shell /bin/bash
USER ruby:ruby

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=ruby:ruby /app /app
COPY --from=build /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/

# Copy application code
COPY --chown=ruby:ruby . .

# Start the server
EXPOSE 8080
CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "8080"]
# CMD ["ruby", "azeema.rb"]
