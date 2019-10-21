# Notes for running experiments on AWS

## AWS setup

Key details of our AWS setup are listed below. Note that this setup is 
largely automated by the `run-experiments.py` script.

* *AWS region:* us-east-1 (North Virginia)
* *EMR release:* 5.17.0 (Spark 2.3.1, Amazon Hadoop 2.8.4)
* Spark deployed in cluster mode (YARN cluster)
* *Master node:* an m4.large instance (4 vCore, 8 GiB memory, 32 GiB EBS storage)
* *Slave nodes:* m5.xlarge instances (4 vCore, 16 GiB memory, 32 GiB EBS storage)
* One slave node acts as the driver, the rest are executors


## Spark settings

We used the settings below, some of which are recommended in the Amazon EMR 
documentation.
These settings will be configured automatically by the `run-experiment.py` 
script.

| Classification | Property                                                              | Value  |
|----------------|-----------------------------------------------------------------------|--------|
| spark          | maximizeResourceAllocation                                            | true   |
| spark-defaults | spark.ui.retainedTasks                                                | 100000 |
| spark-defaults | spark.executor.heartbeatInterval                                      | 20s    |
| spark-defaults | spark.locality.wait                                                   | 50ms   |
| spark-defaults | spark.eventLog.enabled                                                | false  |
| spark-defaults | spark.ui.retainedStages                                               | 1000   |
| spark-defaults | spark.ui.retainedJobs                                                 | 1000   |
| spark-log4j    | log4j.logger.org.apache.parquet                                       | ERROR  |
| spark-log4j    | log4j.logger.org.apache.spark                                         | WARN   |
| spark-log4j    | log4j.logger.parquet                                                  | ERROR  |
| spark-log4j    | log4j.logger.org.spark_project.jetty.util.component.AbstractLifeCycle | ERROR  |
| spark-log4j    | log4j.logger.com.github.ngmarchant.dblink                             | INFO   |


## Before running the script...

1. The dblink JAR file should be stored in an S3 bucket. 
You should ensure that the `dblink_jar_path` variable in the 
`run-experiment.py` script points to the correct location on S3. 
Currently it is set to `s3://d-blink/dblink-assembly-0.1.jar`.

2. The data sets should also be stored in an S3 bucket. The location of each 
data set is specified in the dblink config files in the `data.path` variable. 
We stored all data sets directly under `s3://dblink/datasets/`.

3. To automate the provisioning of the EMR cluster and the execution of the 
dblink job through the AWS API, it is necessary to set up an IAM access key. 
Access keys consist of two parts: an access key ID and a secret access key. 
Refer to the [IAM documentation](https://docs.aws.amazon.com/en_pv/IAM/latest/UserGuide/id_credentials_access-keys.html) for guidance on setting this up.
Once you have obtained an access key, you should create an empty file at 
`~/.aws/credentials/` with the following content:
```
[default]
aws_access_key_id = <FILL IN>
aws_secret_access_key = <FILL IN>
```

4. In addition to the IAM access key, you will also need to set up EC2 key 
pairs. 
This should be familiar to those who have set up SSH keys for secure 
authentication. 
Guidance is available in the [EC2 documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).
When setting this up, it is important to take note of the key pair name as 
configured in the Amazon EC2 console.
This name should match the `ec2_key_name` variable in the `run-experiment.py` 
script.

5. To specify the AWS region, create an empty file at `~/.aws/config` with 
the following content:
```
[default]
region=us-east-1
emr =
    service_role = EMR_DefaultRole
    instance_profile = EMR_EC2_DefaultRole
```

6. The `run-experiment.py` script depends on the `pyhocon`, `boto3` and 
`awscli` Python 3 packages.
You can install these using `pip` or create a virtual environment using the 
provided `Pipfile`.

## Executing the script
After completing the above steps, you should be able to run the 
`run-experiment.py` script.
This script will automatically configure a Spark cluster in YARN mode, 
submit the job, and terminate upon completion. 
It is recommended to check the Amazon EMR console, to ensure that the job 
is progressing smoothly.
Note that key results (diagnostics, evaluation results and a point estimate 
of the linkage structure) will be copied to the `destinationPath` specified 
in the copy-files step. 
All other output (including the posterior samples) will be lost after the 
cluster is terminated.

