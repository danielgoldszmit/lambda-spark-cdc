from pyspark.sql import SparkSession
from pyspark.sql.types import *
import sys
import os
import botocore.session

def lambda_handler(event, context):

 session = botocore.session.get_session()   
 s3_bucket = os.environ['s3_bucket'] 
 s3_prefix_input = os.environ['inp_prefix']
 s3_prefix_output = os.environ['out_prefix']
 aws_region = os.environ['region'] 
 aws_access_key_id = session.get_credentials().access_key
 aws_secret_access_key = session.get_credentials().secret_key
 session_token = session.get_credentials().token 

 input_path = f's3a://{s3_bucket}/{s3_prefix_input}'
 output_path = f's3a://{s3_bucket}/{s3_prefix_output}'

 print(input_path)
 #print('aws_access_key_id: ' + aws_access_key_id)
 #print('aws_secret_access_key: ' + aws_secret_access_key)
 #print(session_token)

 spark = SparkSession.builder \
 .appName("cda-spark-delta-demo") \
 .master("local[*]") \
 .config("spark.driver.bindAddress", "127.0.0.1") \
 .config("spark.hadoop.fs.s3a.access.key", aws_access_key_id) \
 .config("spark.hadoop.fs.s3a.secret.key", aws_secret_access_key) \
 .config("spark.hadoop.fs.s3a.session.token",session_token) \
 .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
 .config("spark.hadoop.fs.s3a.aws.credentials.provider","org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider") \
 .getOrCreate()
 
 print("***************start***********")
 a = str(spark.sparkContext.version)
 print(a)
 df = spark.read.format('csv').option('header','true').option('inferSchema','true').load('%s' % input_path)
 df.show()
 print("***************write delta***********")
 df.write.format("delta").mode("append").save("%s" % output_path)
 spark.sql("CREATE TABLE events USING DELTA LOCATION '%s'" % output_path)
 print("***************read delta***********")
 df_delta=spark.read.format("delta").load("%s" % output_path)  # query table by path
 df_delta.show()
 spark.stop()
 return a
