#!/usr/bin/env python
import boto3
from pyhocon import ConfigFactory
from urllib.parse import urlparse
import math
import os

# Select experiment to run
#config_path = './config-files/ABSEmployee_64partitions_PCG-I.conf'
#config_path = './config-files/NCVR_64_partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_1partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_2partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_4partitions_Gibbs.conf'
#config_path = './config-files/NLTCS_4partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_4partitions_PCG-II.conf'
#config_path = './config-files/NLTCS_8partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_16partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_32partitions_PCG-I.conf'
#config_path = './config-files/NLTCS_64partitions_PCG-I.conf'
config_path = './config-files/RLdata10000_2partitions_PCG-I.conf'
#config_path = './config-files/SHIW_8partitions_PCG-I.conf'

# Need to upload the dblink fat JAR to S3 and update the URI below accordingly
dblink_jar_path = 's3://d-blink/dblink-assembly-0.1.jar'
ec2_key_name = 'X1 Carbon G5'

def get_security_groups(VpcId):
    """
    Create master and slave security groups for EMR on VpcId
    :param VpcId:
    :return:
    """
    ec2 = boto3.resource('ec2')

    # Delete existing security groups, since we can't overwrite them
    security_groups = ec2.security_groups.filter(Filters=[{'Name': 'vpc-id', 'Values': [VpcId]}])

    master = next((s for s in security_groups if s.group_name == 'EMR-master'), None)
    if not master:
        master = ec2.create_security_group(GroupName='EMR-master',
                                           Description='Master group for Elastic MapReduce',
                                           VpcId=vpc_id)
    print('Security Group Created %s in vpc %s.' % (master.id, VpcId))

    slave = next((s for s in security_groups if s.group_name == 'EMR-slave'), None)
    if not slave:
        slave = ec2.create_security_group(GroupName='EMR-slave',
                                          Description='Slave group for Elastic MapReduce',
                                          VpcId=VpcId)
    print('Security Group Created %s in vpc %s.' % (slave.id, VpcId))

    # IP permissions are the same for master and slave
    ip_permissions = [
        # permit SSH
        {
            'IpProtocol': 'tcp',
            'FromPort': 22,
             'ToPort': 22,
             'IpRanges': [{'CidrIp': '0.0.0.0/0'}],
            'Ipv6Ranges': [{'CidrIpv6': '::/0'}]
        },
        # all traffic
        {
            'IpProtocol': '-1',
            'FromPort': -1,
            'ToPort': -1,
            'UserIdGroupPairs': [{'GroupId': master.id}, {'GroupId': slave.id}]
        }
    ]

    for group in [master, slave]:
        group.revoke_ingress(IpPermissions=ip_permissions)
        data = group.authorize_ingress(IpPermissions=ip_permissions)
        print('Ingress Successfully Set %s' % data)

    return {'masterSecurityGroup': master.id, 'slaveSecurityGroup': slave.id}

def get_out_path(config):
    """
    Returns path where summary output is copied after d-blink finishes running

    :param config: ConfigTree
    :return: path if it exists, otherwise None
    """
    steps = config.get_list('dblink.steps')
    copy_steps = [a for a in steps if a.get_string('name') == 'copy-files'] # filter out 'copy-files' steps
    if len(copy_steps) == 0:
        return None
    if len(copy_steps) == 1:
        return copy_steps[0].get_string('parameters.destinationPath')
    else:
        raise NotImplementedError('Too many copy-files steps')

# Parse config file
config_fname = os.path.basename(config_path)
expt_name = os.path.splitext(config_fname)[0]
config = ConfigFactory.parse_file(config_path)
data_url = urlparse(config.get_string('dblink.dataPath'))
out_url = urlparse(get_out_path(config))
dblink_jar_url = urlparse(dblink_jar_path)
num_levels = config.get_int('dblink.partitioner.properties.numLevels')
num_partitions = 2**num_levels

# Prepare files on S3
s3 = boto3.resource('s3')

# Check data exists on S3 (will raise exception if not)
s3.Object(data_url.netloc, data_url.path.lstrip('/')).load()
s3.Object(dblink_jar_url.netloc, dblink_jar_url.path.lstrip('/')).load()

# Move config file to bucket
s3.Bucket(out_url.netloc).upload_file(config_path, config_fname)

# Set-up cluster
ec2 = boto3.resource('ec2')

region = 'us-east-1'
vpcs = list(ec2.vpcs.all())
#vpc_id = vpcs[0].id
vpc_id = 'vpc-ebfd5991' # may need to be set manually
security_groups = get_security_groups(vpc_id)
subnets = list(ec2.subnets.filter(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]))
emr_client = boto3.client('emr')

# Run d-blink
emr_client.run_job_flow(
    Name=expt_name,
    ReleaseLabel='emr-5.17.0',
    Instances={
        'InstanceGroups': [
            {
                'Name': 'master',
                'InstanceRole': 'MASTER',
                'InstanceType': 'm4.large',
                'InstanceCount': 1,
                'EbsConfiguration': {
                    'EbsBlockDeviceConfigs': [
                        {
                            'VolumeSpecification': {'SizeInGB': 32, 'VolumeType': 'gp2'},
                            'VolumesPerInstance': 1
                        }
                    ]
                }
            },
            {
                'Name': 'slave',
                'InstanceRole': 'CORE',
                'InstanceType': 'm5.xlarge',
                'InstanceCount': 1 + math.ceil(num_partitions/4.0), # TODO: take into account number of threads
                'EbsConfiguration': {
                    'EbsBlockDeviceConfigs': [
                        {
                            'VolumeSpecification': {'SizeInGB': 64, 'VolumeType': 'gp2'},
                            'VolumesPerInstance': 1
                        }
                    ]
                }
            }
        ],
        'KeepJobFlowAliveWhenNoSteps': False,
        'TerminationProtected': False,
        'Ec2KeyName': ec2_key_name,
        'EmrManagedMasterSecurityGroup': security_groups['masterSecurityGroup'],
        'EmrManagedSlaveSecurityGroup': security_groups['slaveSecurityGroup'],
        'Ec2SubnetId': subnets[0].id
    },
    Applications=[{'Name': 'Hadoop'}, {'Name': 'Spark'}],
    Steps=[
        {
            'Name': 'Setup Hadoop debugging',
            'ActionOnFailure': 'TERMINATE_JOB_FLOW',
            'HadoopJarStep': {
                'Jar': 's3://{}.elasticmapreduce/libs/script-runner/script-runner.jar'.format(region),
                'Args': ['s3://{}.elasticmapreduce/libs/state-pusher/0.1/fetch'.format(region)]
            }
        },
        {
            'Name': 'd-blink',
            'ActionOnFailure': 'CONTINUE',
            'HadoopJarStep': {
                'Properties': [],
                'Jar': 'command-runner.jar',
                'Args': [
                    'spark-submit',
                    '--deploy-mode',
                    'cluster',
                    '--class',
                    'com.github.cleanzr.dblink.Run',
                    dblink_jar_path,
                    's3://' + out_url.netloc + '/' + config_fname
                ]
            }
        }
    ],
    Configurations=[
        {
            'Classification': 'spark',
            'Properties': {
                'maximizeResourceAllocation' : 'true'
            }
        },
        {
            'Classification': 'spark-defaults',
            'Properties': {
                'spark.locality.wait': '50ms', # tasks are very short so reduce waiting time from the default of 3s
                'spark.eventLog.enabled': 'false',
                'spark.ui.retainedJobs': '1000',
                'spark.ui.retainedStages': '1000',
                'spark.ui.retainedTasks': '100000',
                'spark.executor.heartbeatInterval': '20s',
                'spark.driver.memory': '10356M', # increase driver memory: specific to m5.xlarge instances
                'spark.yarn.maxAppAttempts': '1'
            }
        },
        {
            'Classification': 'spark-log4j',
            'Properties': {
                'log4j.logger.com.github.cleanzr.dblink': 'INFO',
                'log4j.logger.org.spark_project.jetty.util.component.AbstractLifeCycle': 'ERROR',
                'log4j.logger.org.apache.parquet': 'ERROR',
                'log4j.logger.parquet': 'ERROR',
                'log4j.logger.org.apache.spark': 'WARN'
            }
        }
    ],
    VisibleToAllUsers=True,
    JobFlowRole='EMR_EC2_DefaultRole',
    ServiceRole='EMR_DefaultRole',
    LogUri='s3://' + out_url.netloc + '/logs/' + expt_name + '/',
    EbsRootVolumeSize=20
)


# Get files off S3
