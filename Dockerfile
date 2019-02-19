FROM ubuntu:18.04

# Set environment variables.
ENV GOROOT=/usr/local/go \
    GOPATH=/usr/local/pavan/ \
    GOBIN=/usr/local/pavan/bin \
    KUBECTL_VERSION=v1.11.7 \
    CONFLUENT_VERSION=5.0 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

#To Export the PATH Variable
ENV PATH "${GOROOT}:${GOPATH}:${GOBIN}:${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/local/go/bin"
  
#installing zip,unzip,curl
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils \
    && echo '**Installing zip,unzip,curl **' \
    && apt-get install -y zip \
    && apt-get install -y unzip \
    && apt-get install -y curl \
    && apt-get install -y wget

# install pre-requisites and Confluent
RUN set -x \
    && apt-get update \
    && apt-get install -y openjdk-8-jre-headless wget netcat-openbsd software-properties-common \
    && wget -qO - http://packages.confluent.io/deb/$CONFLUENT_VERSION/archive.key | apt-key add - \
    && add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/$CONFLUENT_VERSION stable main" \
    && apt-get update \
    && apt-get install -y confluent-platform-oss-2.11

# install kubectl
CMD echo "*************** Installing kubectl ******************"
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl
CMD echo "*************** kubectl Installation Completed ******************"

# install GO and Dep and Git
RUN echo '*************** Creating directory for GO ******************' \
    && mkdir  /usr/local/pavan/ \
    && mkdir /usr/local/pavan/bin \
    && echo '*************** Installing Go ******************' \
    && curl https://storage.googleapis.com/golang/go1.11.5.linux-amd64.tar.gz | tar xvzf - -C /usr/local \
    && echo '**Installing Git **' \
    && apt-get install -y git \
    && echo '*************** Installing Dep ******************' \
    && curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh 

# install Operator Framework
RUN mkdir -p $GOPATH/src/github.com/operator-framework \
    && cd $GOPATH/src/github.com/operator-framework \
    && echo '*************** Fetching framework ******************' \
    && git clone https://github.com/operator-framework/operator-sdk \
    && cd operator-sdk \
    && git checkout master \
    && apt-get install -y make \
    && make dep \
    && make install
    
RUN mkdir /usr/local/pavan/src/github.com/k8soperator \
    && chmod 777 -R /usr/local/pavan/src/github.com/k8soperator \
    && chmod 777  -R /usr/local/pavan/pkg/dep \
    && cd /usr/local/pavan/src/github.com/k8soperator \
    && operator-sdk new app-operator --skip-git-init

RUN chmod 777  -R /usr/local/pavan/ \
    && apt-get install -y vim \
    $$ apt-get install docker

# Define default command.
CMD trap : TERM INT; sleep infinity & wait
