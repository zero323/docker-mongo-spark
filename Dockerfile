FROM ubuntu:16.04

# See https://github.com/phusion/baseimage-docker/issues/58
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update \
    && apt-get install -y wget ipython python-setuptools build-essential python-dev python-pip openjdk-7-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

RUN pip install pymongo

ENV SPARK_VERSION 1.6.1
ENV HADOOP_VERSION 2.6
ENV MONGO_HADOOP_VERSION 1.5.1
ENV MONGO_HADOOP_COMMIT r1.5.1

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV SPARK_HOME /usr/local/spark

ENV APACHE_MIRROR http://ftp.ps.pl/pub/apache
ENV SPARK_URL ${APACHE_MIRROR}/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
ENV SPARK_DIR spark-${SPARK_VERSION}-bin-hadoop2.6

ENV MONGO_HADOOP_URL https://github.com/mongodb/mongo-hadoop/archive/${MONGO_HADOOP_COMMIT}.tar.gz

ENV MONGO_HADOOP_LIB_PATH /usr/local/mongo-hadoop/build/libs
ENV MONGO_HADOOP_JAR  ${MONGO_HADOOP_LIB_PATH}/mongo-hadoop-${MONGO_HADOOP_VERSION}-SNAPSHOT.jar

ENV MONGO_HADOOP_SPARK_PATH /usr/local/mongo-hadoop/spark
ENV MONGO_HADOOP_SPARK_JAR ${MONGO_HADOOP_SPARK_PATH}/build/libs/mongo-hadoop-spark-${MONGO_HADOOP_VERSION}-SNAPSHOT.jar
ENV PYTHONPATH  ${MONGO_HADOOP_SPARK_PATH}/src/main/python

ENV SPARK_DRIVER_EXTRA_CLASSPATH ${MONGO_HADOOP_JAR}:${MONGO_HADOOP_SPARK_JAR}
ENV CLASSPATH ${SPARK_DRIVER_EXTRA_CLASSPATH}
ENV JARS ${MONGO_HADOOP_JAR},${MONGO_HADOOP_SPARK_JAR}

ENV PYSPARK_DRIVER_PYTHON /usr/bin/ipython
ENV PATH $PATH:$SPARK_HOME/bin

# Download  Spark
RUN wget -qO - ${SPARK_URL} | tar -xz -C /usr/local/ \
    && cd /usr/local && ln -s ${SPARK_DIR} spark

RUN wget -qO - ${MONGO_HADOOP_URL} | tar -xz -C /usr/local/ \
    && mv /usr/local/mongo-hadoop-${MONGO_HADOOP_COMMIT} /usr/local/mongo-hadoop \
    && cd /usr/local/mongo-hadoop \
    && ./gradlew jar

RUN echo "spark.driver.extraClassPath   ${CLASSPATH}" > $SPARK_HOME/conf/spark-defaults.conf

RUN groupadd -r spark && useradd -r -g spark spark

USER spark

CMD ["/bin/bash"]

