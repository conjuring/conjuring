FROM casperdcl/conjuring:base as core
LABEL com.jupyter.source="https://hub.docker.com/r/jupyterhub/jupyterhub/dockerfile"
# modified version of above on this date
LABEL com.jupyter.date="2019-07-01"
LABEL org.jupyter.service="jupyterhub"

RUN apt-get -yqq update && apt-get -yqq upgrade && apt-get -yqq install \
  wget git bzip2 \
  && apt-get purge && apt-get clean && rm -rf /var/lib/apt/lists/*

# ensure Python is installed with conda
RUN which conda || ( \
  wget -q https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O /tmp/miniconda.sh \
  && echo 'e1045ee415162f944b6aebfe560b8fee */tmp/miniconda.sh' | md5sum -c - \
  && bash /tmp/miniconda.sh -f -b -p /opt/conda \
  && rm /tmp/miniconda.sh \
  && /opt/conda/bin/conda update --all -y -c conda-forge \
  && /opt/conda/bin/conda clean -a -y \
)
# auto-find conda helper script
COPY src/conda.sh /

# install pip
RUN /conda.sh install -c conda-forge -q -y pip \
 && /conda.sh path_exec pip install --no-cache-dir -U pip

# install NodeJS and Jupyter with conda
RUN /conda.sh install -y -c conda-forge \
    sqlalchemy tornado jinja2 traitlets requests pip pycurl nodejs configurable-http-proxy \
  && /conda.sh install -y -c conda-forge notebook jupyterlab \
  && /conda.sh clean -a -y

RUN /conda.sh path_exec pip install --no-cache-dir -U jupyterhub

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/
EXPOSE 8000
ENTRYPOINT ["/conda.sh", "path_exec"]
CMD ["jupyterhub"]

## first half (rarely changing core) complete ##
## ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ##
## second half (user customisable build) ##

FROM core as conjuring

COPY src/null custom/apt.tx[t] ./
RUN [ -f apt.txt ] && apt-get -yqq update \
  && (cat apt.txt | xargs apt-get -yqq install) \
  && apt-get purge && apt-get clean \
  && rm -rf /var/lib/apt/lists/* ; \
  rm -f src/null apt.txt

COPY src/env2conda.sh custom/environment*.yml ./
RUN ./env2conda.sh /conda.sh environment*.yml \
  && /conda.sh clean -a -y \
  && rm -f env2conda.sh environment*.yml

COPY src/null custom/requirements.tx[t] ./
RUN [ -f requirements.txt ] \
  && /conda.sh path_exec pip install --no-cache-dir -r requirements.txt \
  && rm -f src/null requirements.txt

# list of users
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} conjuring
RUN useradd -D -s /bin/bash -N
COPY src/csv2useradd.sh custom/users.csv /opt/
RUN chmod 400 /opt/users.csv  # keep it secret from container users

# jupyterhub config
COPY custom/srv/* ./
#RUN /conda.sh path_exec jupyterhub --generate-certs  # internal_ssl unnecessary

ENV DEBIAN_FRONTEND ''
COPY src/cmd.sh /bin/
CMD ["/bin/cmd.sh"]
