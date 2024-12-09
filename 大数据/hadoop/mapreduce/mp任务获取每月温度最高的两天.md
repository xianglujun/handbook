# mp任务获取每月温度最高的两天

## Weather

```java
package org.hadoop.learn.mp.temporary;

import lombok.Data;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * 天气数据
 */
@Data
public class Weather implements WritableComparable<Weather> {

    private static final String TIME_FORMAT = "yyyy-MM-dd HH:mm:ss";

    private Integer year;
    private Integer month;
    private Integer day;

    private String dateTimeStr;

    private Date time;

    private Double temporary;

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeInt(this.year);
        out.writeInt(this.month);
        out.writeInt(this.day);

        out.writeUTF(this.dateTimeStr);
        out.writeDouble(this.temporary);
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        this.year = in.readInt();
        this.month = in.readInt();
        this.day = in.readInt();

        this.dateTimeStr = in.readUTF();
        this.temporary = in.readDouble();

        try {
            if (this.dateTimeStr != null && !this.dateTimeStr.equals("")) {
                SimpleDateFormat sdf = new SimpleDateFormat(TIME_FORMAT);
                this.time = sdf.parse(this.dateTimeStr);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public int compareTo(Weather o) {
        if (o == null) {
            return -1;
        }

        // 这里按照年月倒序排，然后按照温度倒序排
        String yearMonth = this.year + "-" + this.month;
        String targetYearMonth = o.getYear() + "-" + o.getMonth();

        int cr = yearMonth.compareTo(targetYearMonth);

        if (cr == 0) {
            cr = this.temporary.compareTo(o.getTemporary());
        }

        return -cr;
    }

    /**
     * 自定义比较器
     */
    public static class WeatherComparator extends WritableComparator {

        public WeatherComparator() {
            super(Weather.class);
        }

        static {
            WritableComparator.define(Weather.class, new WeatherComparator());
        }

        @Override
        public int compare(WritableComparable a, WritableComparable b) {
            return super.compare(a, b);
        }
    }
}
```

## WeatherGroupingComparator

```java
package org.hadoop.learn.mp.temporary;

import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class WeatherGroupingComparator extends WritableComparator {

    Logger logger = LoggerFactory.getLogger(WeatherGroupingComparator.class);

    protected WeatherGroupingComparator() {
        super(Weather.class, true);
    }

    @Override
    public int compare(WritableComparable a, WritableComparable b) {

        logger.error("WeatherGroupingComparator........................");

        Weather w1 = (Weather) a;
        Weather w2 = (Weather) b;

        String yearMonth = w1.getYear() + "-" + w1.getMonth();
        String targetYearMonth = w2.getYear() + "-" + w2.getMonth();
        return yearMonth.compareTo(targetYearMonth);
    }
}
```

## WeatherMapper

```java
package org.hadoop.learn.mp.temporary;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

/**
 * 天气数据mapper处理
 */
public class WeatherMapper extends Mapper<LongWritable, Text, Weather, Weather> {

    private static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";
    private static final String TEMP_END_SUFFIX = "°C";

    @Override
    protected void map(LongWritable key, Text value, Context context) throws java.io.IOException, InterruptedException {
        String line = value.toString().trim();
        String[] splits = line.split("\\s+");
        String timeFormatStr = splits[0] + " " + splits[1];

        SimpleDateFormat sdf = new SimpleDateFormat(DATE_FORMAT);
        Weather outValue = new Weather();
        Text outKey = new Text();
        try {
            Date datetime = sdf.parse(timeFormatStr);
            outValue.setTime(datetime);

            Calendar calendar = Calendar.getInstance();
            calendar.setTime(datetime);

            outValue.setYear(calendar.get(Calendar.YEAR));
            outValue.setMonth(calendar.get(Calendar.MONTH) + 1);
            outValue.setDay(calendar.get(Calendar.DAY_OF_MONTH));
            outValue.setDateTimeStr(timeFormatStr);


            String temperature = splits[2];
            outValue.setTemporary(Double.parseDouble(temperature.substring(0, temperature.length() - TEMP_END_SUFFIX.length())));

            outKey.set(splits[0].substring(0, splits[0].lastIndexOf("-")));
        } catch (ParseException e) {
            throw new RuntimeException(e);
        }

        context.write(outValue, outValue);
    }
}
```

## WeatherPartitioner

```java
package org.hadoop.learn.mp.temporary;

import org.apache.hadoop.mapreduce.Partitioner;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * 分区器
 */
public class WeatherPartitioner extends Partitioner<Weather, Weather> {
    Logger logger = LoggerFactory.getLogger(WeatherPartitioner.class);
    @Override
    public int getPartition(Weather text, Weather weather, int numPartitions) {
        logger.error("执行partitioner................");
        return (weather.getYear() + weather.getMonth()) % numPartitions;
    }
}
```

## WeatherReducer

```java
package org.hadoop.learn.mp.temporary;

import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class WeatherReducer extends Reducer<Weather, Weather, Text, DoubleWritable> {
    @Override
    protected void reduce(Weather key, Iterable<Weather> values, Reducer<Weather, Weather, Text, DoubleWritable>.Context context) throws IOException, InterruptedException {
        System.out.println("开始处理" + key.toString() + "的温度数据");
        int day = -1;
        for (Weather w : values) {
            if (day == -1) {
                context.write(new Text(w.getDateTimeStr()), new DoubleWritable(w.getTemporary()));
                day = w.getDay();
            } else if (day != w.getDay()) {
                context.write(new Text(w.getDateTimeStr()), new DoubleWritable(w.getTemporary()));
                day = w.getDay();
                break; // 只取两天，所以执行到这里就代表已经获取到了两天的数据
            }
        }
    }
}
```

## WeatherSortComparator

```java
package org.hadoop.learn.mp.temporary;

import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class WeatherSortComparator extends WritableComparator {

    Logger logger = LoggerFactory.getLogger(WeatherSortComparator.class);

    public WeatherSortComparator() {
        super(Weather.class, true);
    }

    @Override
    public int compare(WritableComparable a, WritableComparable b) {

        logger.error("执行WeatherSortComparator...............");

        Weather w1 = (Weather) a;
        Weather w2 = (Weather) b;
        return w1.compareTo(w2);
    }
}
```

## WeatherMain

```java
package org.hadoop.learn.mp.temporary;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.FileInputFormat;
import org.apache.hadoop.mapred.FileOutputFormat;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapreduce.Job;
import org.hadoop.learn.mp.wordcount.WordCountReducer;

import java.io.IOException;

public class WeatherMain {
    public static void main(String[] args) throws IOException, InterruptedException, ClassNotFoundException {
        if (args == null || args.length == 0 || args.length != 2) {
            System.out.println("请输入输入/输出路径");
            return;
        }

        System.setProperty("HADOOP_HOME", "H:\\xianglujun\\hadoop-2.6.5");
        System.setProperty("hadoop.home.dir", "H:\\xianglujun\\hadoop-2.6.5");
        System.setProperty("HADOOP_USER_NAME", "root");

        Configuration cnf = new Configuration();

        // 设置本地运行
//        cnf.set("mapreduce.framework.name", "local");

        JobConf jobConf = new JobConf(cnf);
        // 设置作业的输入输出路径
        FileInputFormat.addInputPath(jobConf, new Path(args[0]));

        Path outputPath = new Path(args[1]);
        FileOutputFormat.setOutputPath(jobConf, outputPath);

        Job job = Job.getInstance(jobConf);

        FileSystem fs = FileSystem.get(cnf);
        if (fs.exists(outputPath)) {
            fs.delete(outputPath, true);
        }

        job.setJarByClass(WeatherMain.class);
        job.setMapperClass(WeatherMapper.class);
        job.setGroupingComparatorClass(WeatherGroupingComparator.class);

        job.setReducerClass(WordCountReducer.class);
        job.setJobName("weather_comparator");
        job.setSortComparatorClass(WeatherSortComparator.class);

        // 设置输出key的类型
        job.setMapOutputKeyClass(Weather.class);
        job.setMapOutputValueClass(Weather.class);
        job.setPartitionerClass(WeatherPartitioner.class);

        // 设置reducer的相关
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(DoubleWritable.class);
        job.setReducerClass(WeatherReducer.class);
        // 设置4个reducer任务，也决定了分区的数量
        job.setNumReduceTasks(4);

        // 提交作业并等待作业结束
        boolean b = job.waitForCompletion(true);

        System.out.println("任务是否执行完成: " + b);
    }
}
```

## 配置文件参考如下

### core-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <!-- 指定访问HDFS的时候路径的默认前缀 / hdfs://localhost:9000 -->
    <property>
        <name>fs.defaultFS</name>
        <!-- 在高可用模式下，不能写单独的namenode的路径，而是需要以集群的方式配置和访问  -->
        <!--<value>hdfs://192.168.56.102:9000</value>-->
        <value>hdfs://mycluster</value>
    </property>
    <!-- 指定hadoop的临时目录位置，他会给namenode, secondarynamenode以及datanode的存储目录指定前缀  -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/apps/hadoop/hadoop-2.6.5/ha</value>
    </property>
    <!-- 指定每个zookeeper服务器的位置和客户端编号  -->
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>192.168.56.102:2181,192.168.56.103:2181,192.168.56.104:2181</value>
    </property>
</configuration>
```

### hdfs-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <!-- 指定block副本数  -->
    <property>
        <name>dfs.replication</name>
                <value>2</value>
    </property>
    <!-- 指定secondarynamenode所在的位置 -->
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>192.168.56.102:50090</value>
    </property>

    <property>
        <name>dfs.namenode.rpc-address</name>
        <value>0.0.0.0:9000</value>
    </property>
    <property>
                <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
                <value>false</value>
        </property>
    <property>
                <name>dfs.datanode.use.datanode.hostname</name>
                <value>true</value>
        </property>
    <property>
                <name>dfs.client.use.datanode.hostname</name>
                <value>true</value>
    </property>
    <!-- 解析参数 dfs.nameservices 值 hdfs://mycluster的地址  -->
    <property>
                <name>dfs.nameservices</name>
                <value>mycluster</value>
    </property>
    <!--mycluster由以下两个namenode-->
    <property>
                <name>dfs.ha.namenodes.mycluster</name>
                <value>nn1,nn2</value>
    </property>

    <!--指定nn1地址和端口号-->
    <property>
                <name>dfs.namenode.rpc-address.mycluster.nn1</name>
                <value>node1:8020</value>
    </property>
    <!--指定nn2地址和端口号-->
    <property>
                <name>dfs.namenode.rpc-address.mycluster.nn2</name>
                <value>node2:8020</value>
    </property>
    <!--指定客户端查找active的namenode的策略：会给所有的namenode发请求，以决定哪个是active的namenode-->
    <property>
                <name>dfs.client.failover.proxy.provider.mycluster</name>
                <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>
    <!--指定三台journal node服务器地址-->
    <property>
                <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://node1:8485;node2:8485;node3:8485/mycluster</value>
    </property>

    <property>
                <name>dfs.journalnode.edits.dir</name>
        <value>/opt/apps/hadoop/hadoop-2.6.5/ha/jnn</value>
    </property>
    <!--当active nn出现故障时，ssh到对应的服务器，将namenode进程kill-->
    <property>
                <name>dfs.ha.fencing.methods</name>
                <value>sshfence</value>
    </property>

    <property>
                <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/root/.ssh/id_rsa</value>
    </property>
    <!--启动NN故障自动切换-->
    <property>
                <name>dfs.ha.automatic-failover.enabled</name>
                <value>true</value>
    </property>
</configuration>
```

### mapred-site.xml

```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
    <!--指定mr作业运行的框架：要么本地运行，要么使用classic(MRv1)，要么使用yarn-->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
```

### yarn-site.xml

```xml
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>

    <!-- Site specific YARN configuration properties -->
    <!-- 让yarn的容器支持mapreduce的洗牌，开启shuffle服务  -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

        <!-- 启用resoucemanager的HA -->
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>

        <!-- 指定zookeeper集群的各个节点地址和端口号 -->
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>node1:2181,node2:2181,node3:2181</value>
    </property>

        <!-- 标识集群，以确保RM不会接管另一个集群的活动 -->
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>cluster1</value>
        </property>
        <!-- RM HA的两个ResourceManager的名字 -->
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>

        <!-- 指定rm1的resourcemanager进程所在的主机名称 -->
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>node1</value>
    </property>

        <!-- 指定rm2的resourcemanager进程所在的主机名称 -->
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>node4</value>
        </property>
</configuration>
```
