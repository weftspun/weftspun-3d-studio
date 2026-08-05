# The development container. RFD 0056 records why it exists.
#
# Fedora, and not Debian slim. Three reasons, and each one was a
# failure first.
#
# 1. systemd and quadlet. Quadlet is a systemd generator that Podman
#    ships, and it turns a unit file into a running container. Debian
#    slim carries no systemd at all.
# 2. The CA bundle. OTP 27 validates key usage strictly, and the
#    bookworm bundle failed `mix local.hex` with:
#      key_usage_mismatch ... CLIENT ALERT: Fatal - Unsupported Certificate
# 3. XLA links against shared libraries a musl base does not carry,
#    thus Alpine was never an option either.
#
# vast.ai runs Linux too. RFD 0055 selects it, so this container is the
# same kind of system production uses.
FROM fedora:44

ENV LANG=C.UTF-8 \
    MIX_ENV=dev \
    # systemd in a container writes to the journal, and not the console.
    container=docker

RUN dnf -y update && dnf -y install \
      # The BEAM.
      erlang elixir \
      # EXLA compiles a NIF.
      gcc gcc-c++ make cmake \
      # The STE linter, the model image check, and prek.
      python3 python3-pip \
      # Podman and quadlet. quadlet is the systemd generator, and it
      # arrives with podman itself.
      podman podman-docker systemd systemd-container \
      # Node for the tooling.
      nodejs npm \
      git curl unzip tar which procps-ng sudo \
    && dnf clean all

# systemd needs these gone, or it fights the container runtime for
# them. This is the standard set for a systemd container.
RUN find /etc/systemd/system /lib/systemd/system \
      -path '*.wants/*' \
      \( -name '*getty*' -o -name '*udev*' -o -name '*systemd-logind*' \) \
      -exec rm -f {} + 2>/dev/null || true

# The dev container feature set expects this user. Running as root
# leaves root-owned files in the bind mount.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Rootless podman needs a subuid range, which quadlet then uses.
RUN echo "${USERNAME}:100000:65536" > /etc/subuid \
    && echo "${USERNAME}:100000:65536" > /etc/subgid

# The agent. It runs in the container, thus it sees the same Elixir and
# the same Docker the build does.
RUN npm install -g @anthropic-ai/claude-code

USER ${USERNAME}
RUN mix local.hex --force && mix local.rebar --force

USER root
WORKDIR /workspaces

# systemd as pid 1, so quadlet units start. devcontainer.json sets
# overrideCommand false, or this never runs.
CMD ["/sbin/init"]
