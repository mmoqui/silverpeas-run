FROM ubuntu:jammy

MAINTAINER Miguel Moquillon "miguel.moquillon@silverpeas.org"

ENV TERM=xterm
ENV TZ=Europe/Paris

# Because the local Maven repository is shared between different container and that repository is
# located in the current user home in the host
ARG USER_ID=1000
ARG GROUP_ID=1000

# Default locale of the platform. It can be overriden to build an image for a specific locale other than en_US.UTF-8.
ARG DEFAULT_LOCALE=fr_FR.UTF-8
ARG SILVERPEAS_VERSION=6.4-build240329
ARG WILDFLY_VERSION=26.1.3
ARG JAVA_VERSION=11

#
# Install required and recommended programs for Silverpeas
#

# Installation of LibreOffice, ImageMagick, Ghostscript, and then
# the dependencies required to run SWFTools and PDF2JSON
RUN apt-get update \
  && apt-get install -y tzdata \
  && apt-get install -y \
    wget \
    curl \
    psmisc \
    iputils-ping \
    vim \
    locales \
    procps \
    net-tools \
    locales \
    language-pack-en \
    language-pack-fr \
    zip \
    unzip \
    openjdk-${JAVA_VERSION}-jdk \
    ffmpeg \
    imagemagick \
    ghostscript \
    libreoffice \
    ure \
    gpgv \
  && groupadd -g ${GROUP_ID} silveruser \
  && useradd -u ${USER_ID} -g ${GROUP_ID} -G users -d /home/silveruser -s /bin/bash -m silveruser \
  && mkdir /home/silveruser/.m2 \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates -f

# Fetch and install SWFTools
RUN wget -nc https://www.silverpeas.org/files/swftools-bin-0.9.2.zip \
  && echo 'd40bd091c84bde2872f2733a3c767b3a686c8e8477a3af3a96ef347cf05c5e43 *swftools-bin-0.9.2.zip' | sha256sum - \
  && unzip swftools-bin-0.9.2.zip -d / \
  && rm swftools-bin-0.9.2.zip

# Fetch and install PDF2JSON
RUN wget -nc https://www.silverpeas.org/files/pdf2json-bin-0.68.zip \
  && echo 'eec849cdd75224f9d44c0999ed1fbe8764a773d8ab0cf7fff4bf922ab81c9f84 *pdf2json-bin-0.68.zip' | sha256sum - \
  && unzip pdf2json-bin-0.68.zip -d / \
  && rm pdf2json-bin-0.68.zip

# Generate locales and set the default one
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=${DEFAULT_LOCALE} LANGUAGE=${DEFAULT_LOCALE} LC_ALL=${DEFAULT_LOCALE} \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

ENV LANG=${DEFAULT_LOCALE}
ENV LANGUAGE=${DEFAULT_LOCALE}
ENV LC_ALL=${DEFAULT_LOCALE}

#
# Install Silverpeas and Wildfly
#

# do some fancy footwork to create a JAVA_HOME that's cross-architecture-safe
RUN ln -svT "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-$(dpkg --print-architecture)" /docker-java-home

# Set up environment variables for Silverpeas
ENV JAVA_HOME=/docker-java-home
ENV SILVERPEAS_HOME=/home/silveruser/silverpeas
ENV JBOSS_HOME=/home/silveruser/wildfly
ENV SILVERPEAS_DEV_MODE=true
ENV SILVERPEAS_DIST_DIR=/home/silveruser/webapp

LABEL name="Silverpeas 6" description="Image to install and to run Silverpeas 6 for development purpose" vendor="Silverpeas"

# Fetch both Silverpeas and Wildfly and unpack them into /home/silveruser
RUN wget -nc https://www.silverpeas.org/files/silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip \
  && wget -nc https://www.silverpeas.org/files/silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip.asc \
  && gpg --keyserver keys.openpgp.org --recv-keys 3F4657EF9C591F2FEA458FEBC19391EB3DF442B6 \
  && gpg --batch --verify silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip.asc silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip \
  && wget -nc https://www.silverpeas.org/files/wildfly-${WILDFLY_VERSION}.Final.zip \
  && unzip silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip -d /home/silveruser \
  && unzip wildfly-${WILDFLY_VERSION}.Final.zip -d /home/silveruser \
  && mv /home/silveruser/silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?} /home/silveruser/silverpeas \
  && mv /home/silveruser/wildfly-${WILDFLY_VERSION}.Final /home/silveruser/wildfly \
  && rm *.zip

# Copy the Maven settings.xml required to install Silverpeas by fetching the software bundles from
# the Silverpeas Nexus Repository
COPY src/settings.xml /home/silveruser/.m2/

# Copy the customized Silverpeas installation settings
COPY src/silverpeas.gradle ${SILVERPEAS_HOME}/bin/

# Copy this container init script that will be run each time the container is ran
COPY src/inputrc /home/silveruser/.inputrc
COPY src/config.properties ${SILVERPEAS_HOME}/configuration/
COPY src/converter.groovy ${SILVERPEAS_HOME}/configuration/silverpeas/
COPY src/CustomerSettings.xml ${SILVERPEAS_HOME}/configuration/silverpeas/
COPY src/data ${SILVERPEAS_HOME}/data

# Copy additional application parameters file to Silverpeas
COPY src/domain1Snowpeas.properties ${SILVERPEAS_HOME}/properties/org/silverpeas/domains/
COPY src/autDomain1Snowpeas.properties ${SILVERPEAS_HOME}/properties/org/silverpeas/authentication/
COPY src/domainIcePeas.properties ${SILVERPEAS_HOME}/properties/org/silverpeas/domains/
COPY src/autDomainIcePeas.properties ${SILVERPEAS_HOME}/properties/org/silverpeas/authentication/

RUN sed -i -e "s/SILVERPEAS_VERSION/${SILVERPEAS_VERSION}/g" ${SILVERPEAS_HOME}/bin/silverpeas.gradle \
  && mkdir -p /home/silveruser/webapp \
  && chown -R silveruser:silveruser /home/silveruser/

# Set the default working directory
WORKDIR ${SILVERPEAS_HOME}/bin
USER silveruser

# Volume in which are stored the data of Silverpeas to avoid to be lost at each container upgrade
VOLUME ["/home/silveruser/silverpeas/data"]

#
# Expose image entries. By default, when running, the container will set up Silverpeas and Wildfly
# according to the host environment.
#

# Silverpeas listens port 8000 by default. 9990 is the Wildfly administrative port and 5005 is the
# debugging port
EXPOSE 8000 9990 5005