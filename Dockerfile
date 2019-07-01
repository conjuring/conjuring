FROM casperdcl/conjuring:base as core
LABEL com.jupyter.source="https://hub.docker.com/r/jupyterhub/jupyterhub/dockerfile"
LABEL com.jupyter.date="2019-07-01"  # modified version of above on this date
LABEL org.jupyter.service="jupyterhub"

# install nodejs, utf8 locale, set CDN because default httpredir is unreliable
RUN apt-get -yqq update && apt-get -yqq upgrade &&  apt-get -yqq install \
  wget git bzip2 \
  && apt-get purge && apt-get clean && rm -rf /var/lib/apt/lists/*

# install Python + NodeJS with conda
RUN wget -q https://repo.continuum.io/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O /tmp/miniconda.sh \
  && echo 'e1045ee415162f944b6aebfe560b8fee */tmp/miniconda.sh' | md5sum -c - \
  && bash /tmp/miniconda.sh -f -b -p /opt/conda \
  && rm /tmp/miniconda.sh \
  && /opt/conda/bin/conda update --all -y -c conda-forge \
  && /opt/conda/bin/conda install -y -c conda-forge python=3.6 \
    sqlalchemy tornado jinja2 traitlets requests pip pycurl nodejs configurable-http-proxy \
  && /opt/conda/bin/pip install -U pip
  && /opt/conda/bin/conda install -y notebook jupyterlab
ENV PATH=/opt/conda/bin:$PATH

RUN pip install --no-cache-dir -U jupyterhub

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/
EXPOSE 8000
CMD ["jupyterhub"]

FROM core as conjuring

# TODO
# ADD custom/apt.txt .
# RUN apt update -qq && cat apt.txt | xargs apt install -yqq
# RUN rm apt.txt

# TODO
# ADD custom/requirements-conda.txt .
# RUN conda install --file requirements-conda.txt
# RUN rm requirements-conda.txt

# TODO: ADD custom/requirements-pip.txt .
# RUN pip install -r requirements-pip.txt
# RUN rm requirements-pip.txt

# list of users
#ARG GROUP_ID=1000
#RUN groupadd -g ${GROUP_ID} conjuring
RUN groupadd conjuring
RUN useradd -D -s /bin/bash -N
RUN useradd -r -G conjuring -m -p $(echo "duper" | openssl passwd -1 -stdin) super

# TODO
# ADD src/csv2useradd.sh .
# ADD custom/users.csv .
# RUN bash csv2useradd.sh users.csv
# RUN rm users.csv
RUN useradd -g conjuring -m -p $(echo "bar" | openssl passwd -1 -stdin) foo

# jupyterhub config
#ADD src/srv/* /srv/jupyterhub/
#RUN chmod 600 /srv/jupyterhub/*.key
#RUN chmod 664 /srv/jupyterhub/*.cert
# unnecessary
#RUN jupyterhub --generate-certs  # internal_ssl

ENV DEBIAN_FRONTEND ''
