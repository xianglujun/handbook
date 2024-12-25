# MapReduce计算流程

- 将block块数据进行逻辑切片计算，每个切片(split)对应一个map任务

- 切片是为了将block数量和map任务数量解耦

- map读取切片数据，默认按行读取，作为键值对浇给map方法，其中key是当前读取的行在文件中的字节偏移量，value就是读取的当前行的内容

- map开始，执行Map任务的自定义实现逻辑

- map将输出的kv首先写到环形缓冲区，在写之前计算分区号(默认按照key的hash值对reducer的个数取模)

- 环形缓冲区默认100MB，预制80%. 如果写入的kv达到了80%则发生溢写，溢写的时候要先对键值对按照分区号进行分区，相同分区按照key的字典顺序排序，溢写到磁盘。如果溢写的文件数量达到了三个，则发生map段归并操作，此时如果指定了combiner, 则按照combiner合并数据

- 当一个map任务完成之后，所有的reducertask向其发送http get请求，下载它们所属分区数据。此过程成为shuffle, 洗牌。

- 当所有的map任务运行结束，开始执行reduce任务

- 在reduce开始之前，根据设定的归并因子，进行多轮的归并操作，非最后一轮的归并的结果被存入到磁盘上，最后一轮归并的结果直接传递给reduce, reduce迭代计算

- reduce计算结束后将结果写到HDFS文件中，每一个reducer task任务都会在作业输出路径下产生一个结果文件part-r-00000. 同时执行成功时会产生一个空的_SUCCESS文件，该文件是一个标识文件.

## 作业提交流程

1. 客户端向ResourceManager获取Job的ID
2. 客户端检查作业输入输出（如果输入路径不存在则抛出异常；如果输出路径存在同样抛出异常）计算切片，解析配置信息
3. 客户端将jar包、配置信息、切片信息上传到HDFS
4. 客户端向ResourceManager发送提交作业的请求
5. ResourceManager调度一个NodeManager， 在NodeManager上的一个容器中运行MRAppMaster, 一个作业对应一个MRAppMaster
6. MRAppMaster首先获取HDFS中的作业信息，计算㜗当前作业需要map的数量，reduce数量
7. MrAppMaster向ResourceManager为map任务申请容器，MRAppMaster跟NodeManager通信启动容器，运行map任务，容器中的YARNChild会首先本地化conf、切片信息以及jar包
8. 当map任务完成达到5%的时候，MRAppMaster向ResourceManager为reduce任务申请容器
9. 当MapReduce中最后一个任务运行结束，MRAppMaster向客户端发送作业完成信息。MapReduce的中间数据销毁，容器销毁，计算结果存储到历史服务器。

## 统计单词数量MR任务实例

### Map任务

```java
package org.hadoop.learn.mp.wordcount;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

/**
 * 第一个参数KEYIN: 读取文件的偏移量
 * 第二个参数VALUEIN: 代表了这一行的文本内容,输入的value类型
 * 第三个参数KEYOUT: 输出的key的value类型
 * 第四个擦拿书VALUEOUT 输出的value类型
 */
public class WordCountMapper extends Mapper<LongWritable, Text, Text, LongWritable> {

    @Override
    protected void map(LongWritable inKey, Text inValue, Mapper<LongWritable, Text, Text, LongWritable>.Context context) throws IOException, InterruptedException {
        // 获取当前行文本内容
        String line = inValue.toString();
        // 按照空行进行拆分
        String[] words = line.split(" ");

        for (String word : words) {
            if (word.isEmpty()) {
                continue;
            }
            context.write(new Text(word), new LongWritable(1));
        }
    }
}
```

### Reduce任务

```java
package org.hadoop.learn.mp.wordcount;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class WordCountReducer extends Reducer<Text, LongWritable, Text, LongWritable> {
    @Override
    protected void reduce(Text key, Iterable<LongWritable> values, Reducer<Text, LongWritable, Text, LongWritable>.Context context) throws IOException, InterruptedException {
        // 定义当前单词出现的总次数
        long sum = 0;
        for (LongWritable value : values) {
            sum += value.get();
        }

        context.write(key, new LongWritable(sum));
    }
}
```

### Main类，启动任务

```java
package org.hadoop.learn.mp.wordcount;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.FileInputFormat;
import org.apache.hadoop.mapred.FileOutputFormat;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapreduce.Job;

import java.io.IOException;

public class WordCountMain {
    public static void main(String[] args) throws IOException, InterruptedException, ClassNotFoundException {
        if (args == null || args.length == 0 || args.length != 2) {
            System.out.println("请输入输入/输出路径");
            return;
        }

        System.setProperty("HADOOP_HOME", "H:\\xianglujun\\hadoop-2.6.5");
        System.setProperty("hadoop.home.dir", "H:\\xianglujun\\hadoop-2.6.5");
        System.setProperty("HADOOP_USER_NAME", "root");

        Configuration configuration = new Configuration();

        // 设置本地运行
        configuration.set("mapreduce.framework.name", "local");

        JobConf jobConf = new JobConf(configuration);
        // 设置作业的输入输出路径
        FileInputFormat.addInputPath(jobConf, new Path(args[0]));
        FileOutputFormat.setOutputPath(jobConf, new Path(args[1]));

        Job job = Job.getInstance(jobConf);

        job.setJarByClass(WordCountMain.class);
        job.setMapperClass(WordCountMapper.class);
        job.setReducerClass(WordCountReducer.class);
        job.setJobName("wordcount");

        // 设置输出key的类型
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(LongWritable.class);

        // 设置reducer的相关
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(LongWritable.class);

        // 提交作业并等待作业结束
        boolean b = job.waitForCompletion(true);

        System.out.println("任务是否执行完成: " + b);
    }
}
```

## 问题解决

### 1. (null) entry in command string: null chmod 0700

这个问题主要出现在windows上开发的时候会出现，这个主要是因为windows中bin版本不支持windows导致的，可以有以下处理步骤

- [GitHub - cdarlint/winutils: winutils.exe hadoop.dll and hdfs.dll binaries for hadoop windows](https://github.com/cdarlint/winutils)下载对应hadoop版本的文件到本地，并替换windows上的bin文件目录

- 在windows中配置HADOOP_HOME的环境变量

- 重启idea,然后在执行程序，这个问题就可以解决了

# 
