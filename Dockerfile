FROM nvidia/cuda:12.6.2-cudnn-devel-ubuntu22.04

ENV HOME="/root"
WORKDIR ${HOME}

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      # PySide6 dependencies
      # https://askubuntu.com/questions/1074926/failed-to-load-module-appmenu-gtk-module-canberra-gtk-module
      appmenu-gtk3-module \
      libcanberra-gtk3-module \
      libglx0 \
      # Qt linux dependencies: https://doc.qt.io/qt-5/linux-requirements.html
      libfontconfig1-dev \
      libfreetype6-dev \
      libx11-dev \
      libx11-xcb-dev \
      libxext-dev \
      libxfixes-dev \
      libxi-dev \
      libxrender-dev \
      libxcb1-dev \
      libxcb-glx0-dev \
      libxcb-keysyms1-dev \
      libxcb-image0-dev \
      libxcb-shm0-dev \
      libxcb-icccm4-dev \
      libxcb-sync-dev \
      libxcb-xfixes0-dev \
      libxcb-shape0-dev \
      libxcb-randr0-dev \
      libxcb-render-util0-dev \
      libxkbcommon-dev \
      libxkbcommon-x11-dev \
      ffmpeg libsm6 libxext6 \
      libegl1 \
      zstd groff \
      make build-essential libssl-dev \
      zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev wget curl llvm unzip \
      libncurses5-dev xz-utils tk-dev libxml2-dev \
      libxmlsec1-dev libffi-dev liblzma-dev git \
      libopenblas-dev libomp-dev \
      libunwind8 ca-certificates && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/*

ARG PYTHON_VERSION="3.10.15"
ARG POETRY_VERSION="1.8.4"

ENV LC_ALL=C.UTF-8

# Install and configure pyenv
ENV PYENV_ROOT="${HOME}/.pyenv"
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
ENV PATH="$HOME/.local/bin:${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"
ENV PYTHON_CONFIGURE_OPTS="--enable-shared"

# Install specific python version
RUN pyenv install ${PYTHON_VERSION}
RUN pyenv global ${PYTHON_VERSION}

# Include python in library path
ENV LD_LIBRARY_PATH=${PYENV_ROOT}/versions/${PYTHON_VERSION}/lib:${LD_LIBRARY_PATH}

# Install and configure poetry using python from pyenv
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=${POETRY_VERSION} python -
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

RUN python -m pip install --upgrade pip

# Install aws cli
RUN pip install awscli

# Prepare app environment
WORKDIR /app
ENV PYTHONIOENCODING=utf8
ENV PIP_NO_CACHE_DIR=true

# Files that are needed to install the package
COPY README.md pyproject.toml poetry.lock ./

# Initialize a virtual environment
RUN poetry env use ~/.pyenv/versions/${PYTHON_VERSION}/bin/python

# Pre-install dependencies, though we haven't added the package code yet. We run this first
# so that, if the dependencies aren't changing, they can remain in a cached Docker layer
RUN poetry install --no-root

# Point to the virtual environment we built
ENV VIRTUAL_ENV=/app/.venv

# Add all files that are allowed by .dockerignore
COPY . .
# Install the root package, which makes it available to dev tools and tests
RUN poetry install

ENTRYPOINT [ "poetry", "run", "python", "./src/run.py" ]
