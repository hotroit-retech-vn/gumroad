FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  wget \
  fontconfig \
  libfreetype6 \
  libjpeg-turbo8 \
  libpng16-16 \
  libxrender1 \
  libxext6 \
  libssl1.1 \
  ca-certificates \
  xfonts-75dpi \
  xfonts-base \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb \
 && dpkg -i wkhtmltox_0.12.6-1.focal_amd64.deb || true \
 && apt-get update \
 && apt-get install -f -y \
 && rm wkhtmltox_0.12.6-1.focal_amd64.deb

ENTRYPOINT ["wkhtmltopdf"]
