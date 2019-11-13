#!/bin/bash
/appdata/spark/spark-2.3.1-bin-hadoop2.7/bin/spark-submit \
    --class com.github.ngmarchant.dblink.Run \
    --master local[*] \
    --driver-memory 128G \
    --conf "spark.driver.extraJavaOptions -Dlog4j.configuration=file:/log4j.properties" \
    --driver-class-path /data/jcgs/dblink-assembly-0.1.jar \
    /data/jcgs/dblink-assembly-0.1.jar \
    /data/jcgs/RLdata10000_2partitions_PCG-I.conf
