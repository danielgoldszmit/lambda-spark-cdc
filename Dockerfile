FROM public.ecr.aws/lambda/python:3.8

ARG HADOOP_VERSION=3.2.0
ARG AWS_SDK_VERSION=1.11.375

RUN yum -y install java-1.8.0-openjdk
RUN pip install --upgrade pip
RUN pip install --no-cache-dir pyspark==3.1.2 awswrangler awscli 

ENV SPARK_HOME="/var/lang/lib/python3.8/site-packages/pyspark"
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PATH=$PATH:$SPARK_HOME/sbin
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH
ENV PATH=$SPARK_HOME/python:$PATH

RUN mkdir $SPARK_HOME/conf
RUN mkdir /root/.aws
# Java esta desatualizado quebra galho com o link simbolico
RUN ln -sf  /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.332.b09-1.amzn2.0.2.x86_64 /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.amzn2.0.1.x86_64

RUN echo "SPARK_LOCAL_IP=127.0.0.1" > $SPARK_HOME/conf/spark-env.sh
RUN echo "log4j.logger.org.apache.hadoop.metrics2=WARN" > $SPARK_HOME/hadoop-metrics2-s3a-file-system.properties

#ENV PYSPARK_SUBMIT_ARGS="--master local pyspark-shell"
#ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.amzn2.0.1.x86_64/jre"
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.332.b09-1.amzn2.0.2.x86_64/jre"
ENV PATH=${PATH}:${JAVA_HOME}/bin

ENV HADOOP_OPTS="-Djava.library.path=$SPARK_HOME/jars"

# Set up the ENV vars for code
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""
ENV AWS_REGION="us-east-1"
ENV AWS_SESSION_TOKEN=""
ENV s3_bucket="s3-naturaeco-us-east-1-dynamic-email-sftp-dev"
ENV inp_prefix="input_crm/natura/br/nat_br_input_crm_20210909.csv"
ENV out_prefix="input_crm/natura/br/nat_br_input_crm_20210909.csv"

RUN yum -y install wget
# copy hadoop-aws and aws-sdk
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar -P ${SPARK_HOME}/jars/ && \ 
    wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar -P ${SPARK_HOME}/jars/

COPY spark-class $SPARK_HOME/bin/
COPY delta-core_2.12-0.8.0.jar ${SPARK_HOME}/jars/
COPY cda_spark_lambda.py ${LAMBDA_TASK_ROOT}
COPY SamAuthenticator.py ${LAMBDA_TASK_ROOT}
COPY mssql-jdbc-11.2.0.jre8.jar ${SPARK_HOME}/jars/

RUN echo ${LAMBDA_TASK_ROOT}

CMD [ "cda_spark_lambda.lambda_handler" ]
