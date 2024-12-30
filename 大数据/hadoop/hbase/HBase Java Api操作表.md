# HBase Java Api操作

## maven依赖

```xml
    <dependencies>
        <dependency>
            <groupId>org.apache.hbase</groupId>
            <artifactId>hbase-client</artifactId>
            <version>2.0.6</version>
        </dependency>
    </dependencies>
```

> maven的依赖最好是和Hbase对应的版本保持一致。

## 操作表

```java
package org.hadoop.hbase.learn;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.Cell;
import org.apache.hadoop.hbase.CellUtil;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;


/**
 * 该类用来测试对HBase的Table的操作
 */
public class HBaseTableTest {

    /**
     * 这个是一个管理类，主要用于HBase的管理，包括创建表，删除表，列族管理等管理员能做的他都能够做
     */
    private Admin admin;
    private Configuration cfg;
    private Connection connection;

    @Before
    public void setUp() throws IOException {
        this.cfg = new Configuration();
        // 让代码能够链接zookeeper,
        cfg.set("hbase.zookeeper.quorum", "node1,node2,node3");
        this.connection = ConnectionFactory.createConnection(cfg);

        this.admin = connection.getAdmin();
    }

    private Table getTable(String tableName) throws IOException {
        Assert.assertNotNull("链接未初始化", this.connection);
        return this.connection.getTable(TableName.valueOf(tableName));
    }

    @Test
    public void createTableIfNotExists() throws IOException {
        String tableName = "api_table";
        TableName tbName = TableName.valueOf(tableName);
        boolean isExists = this.admin.tableExists(tbName);
        if (!isExists) {
            TableDescriptorBuilder builder = TableDescriptorBuilder.newBuilder(TableName.valueOf(tableName));
            builder.setColumnFamilies(HBaseTableUtil.createColumnFamilyDescs("cf1", "cf2"));
            this.admin.createTable(builder.build());
            System.out.println(String.format("创建%s表成功", tableName));
        }
    }

    @Test
    public void getTableInfo() throws IOException {
        String tableName = "api_table";
        TableName tbName = isTableExists(tableName);

        List<TableDescriptor> descriptorList = this.admin.listTableDescriptors(Arrays.asList(tbName));
        Assert.assertTrue("表不存在", descriptorList.size() > 0);
        for (TableDescriptor tableDescriptor : descriptorList) {
            System.out.println("tableName: " + tableDescriptor.getTableName());
            System.out.println("columnFamily: " + Arrays.toString(tableDescriptor.getColumnFamilyNames().toArray()));
            System.out.println("flushPolicyClassName: " + tableDescriptor.getFlushPolicyClassName());
            System.out.println("maxFileSizes: " + tableDescriptor.getMaxFileSize());
            System.out.println("--------------------------------------------------------");
        }
    }

    /**
     * 向表中插入数据
     */
    @Test
    public void putData() throws IOException {
        String tableName = "api_table";
        isTableExists(tableName);

        Table table = this.getTable(tableName);
        Put put = new Put(Bytes.toBytes("1"));
        // 加入一行数据
        put.addColumn(Bytes.toBytes("cf1"), Bytes.toBytes("name"), Bytes.toBytes("zhangsan"));
        put.addColumn(Bytes.toBytes("cf1"), Bytes.toBytes("age"), Bytes.toBytes(18));
        put.addColumn(Bytes.toBytes("cf1"), Bytes.toBytes("sex"), Bytes.toBytes("male"));

        put.addColumn(Bytes.toBytes("cf2"), Bytes.toBytes("address"), Bytes.toBytes("beijing"));
        put.addColumn(Bytes.toBytes("cf2"), Bytes.toBytes("phone"), Bytes.toBytes("123456789"));
        put.addColumn(Bytes.toBytes("cf2"), Bytes.toBytes("email"), Bytes.toBytes("zhangsan@163.com"));

        table.put(put);
    }

    /**
     * 获取一行数据
     */
    @Test
    public void getRow() throws IOException {
        String tableName = "api_table";
        isTableExists(tableName);
        Table table = this.getTable(tableName);

        Result result = table.get(new Get(Bytes.toBytes("1")));
        for (Cell cell : result.rawCells()) {
            System.out.println(Bytes.toString(CellUtil.cloneRow(cell)) + ":" + Bytes.toString(CellUtil.cloneFamily(cell)) + ":" + Bytes.toString(CellUtil.cloneQualifier(cell)) + ":" + Bytes.toString(CellUtil.cloneValue(cell)));
        }
    }

    private TableName isTableExists(String tableName) throws IOException {
        TableName tbName = TableName.valueOf(tableName);

        boolean isExists = this.admin.tableExists(tbName);
        Assert.assertTrue("表不存在", isExists);
        return tbName;
    }

    @Test
    public void deleteTable() throws IOException {
        String tableName = "api_table";
        TableName tbName = isTableExists(tableName);
        this.admin.disableTable(tbName);
        this.admin.deleteTable(tbName);
    }

    @After
    public void destroy() throws IOException {
        if (this.admin != null) {
            this.admin.close();
        }
    }

    public static class HBaseTableUtil {
        public static ColumnFamilyDescriptor createColumnFamilyDesc(String cfName) {
            return ColumnFamilyDescriptorBuilder.newBuilder(cfName.getBytes()).build();
        }

        public static Collection<ColumnFamilyDescriptor> createColumnFamilyDescs(String... cfNames) {
            Collection<ColumnFamilyDescriptor> columnFamilyDescriptors = new ArrayList<>();
            for (String cfName : cfNames) {
                columnFamilyDescriptors.add(createColumnFamilyDesc(cfName));
            }
            return columnFamilyDescriptors;
        }
    }

}
```

## 实例实现

该实例主要是自己生成一个数据，然后做一些数据查询的操作，仅用作学习：

### HBasConnectionHelper

```java
package org.hadoop.learn.phone.log;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ConnectionFactory;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class HBasConnectionHelper {
    private static Configuration cfg = new Configuration();

    private static Map<String, Connection> cache = new ConcurrentHashMap<>();

    static {
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                destroy();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }));

        cfg.set("hbase.zookeeper.quorum", "node1,node2,node3");
    }

    public static Connection getConnection(String flag) throws IOException {
        if (cache.containsKey(flag)) {
            Connection connection = cache.get(flag);
            if (connection != null && !connection.isClosed()) {
                return connection;
            }
        }

        Connection connection = ConnectionFactory.createConnection(cfg);
        cache.put(flag, connection);
        return connection;
    }

    public static void destroy() throws IOException {
        if (!cache.isEmpty()) {
            for (Connection connection : cache.values()) {
                connection.close();
            }
            System.out.println("所有链接已关闭");
        }
    }
}
```

### PhoneLogInitializor

```java
package org.hadoop.learn.phone.log;

import org.apache.hadoop.hbase.NamespaceDescriptor;
import org.apache.hadoop.hbase.NamespaceNotFoundException;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Random;

/**
 * 用于数据初始化，后续的逻辑实现
 */
public class PhoneLogInitializor {

    private static final String SPLITTER = ":";
    private static final String FLAG = "init";

    private TableName tableName;
    private String tbName;
    private String namespace;
    private volatile boolean isInited = false;

    private Connection connection;

    private static final Object MUTEX = new Object();

    public PhoneLogInitializor(String tableName, String namespace) throws IOException {
        this.tableName = TableName.valueOf(namespace + SPLITTER + tableName);
        this.tbName = tableName;
        this.namespace = namespace;
        this.connection = HBasConnectionHelper.getConnection(FLAG);
    }

    /**
     * 随机产生数据，数据格式为:
     * snum: 拨打手机号码
     * rnum: 接听电话号码
     * seonds: 拨打电话时间
     * datetime：拨打时间
     */
    public void randomData() throws IOException {
        synchronized (MUTEX) {
            if (this.isInited) {
                System.err.println("已经初始化，无需再次初始化..");
                return;
            }

            init();

            // 产生数据
            this.generateData();
            this.isInited = true;
        }
    }

    private void generateData() throws IOException {
        Table table = this.connection.getTable(this.tableName);
        Random random = new Random();
        for (int i = 0; i < 10000; i++) {
            String snum = getPhone();
            String rnum = getPhone();
            int seconds = random.nextInt(1000);
            Calendar calendar = getDateTime();
            String datetime = this.sdf.format(calendar.getTime());

            Put put = new Put(Bytes.toBytes(snum + "_" + calendar.getTime().getTime()));
            byte[] base = Bytes.toBytes("base");
            put.addColumn(base, Bytes.toBytes("snum"), Bytes.toBytes(snum));
            put.addColumn(base, Bytes.toBytes("rnum"), Bytes.toBytes(rnum));
            put.addColumn(base, Bytes.toBytes("seconds"), Bytes.toBytes(seconds));
            put.addColumn(base, Bytes.toBytes("datetime"), Bytes.toBytes(datetime));

            table.put(put);
        }
    }

    private SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    private Calendar getDateTime() {
        Random random = new Random();
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.MONTH, random.nextInt(12));
        calendar.set(Calendar.DAY_OF_MONTH, random.nextInt(30));
        calendar.set(Calendar.HOUR_OF_DAY, random.nextInt(24));
        calendar.set(Calendar.MINUTE, random.nextInt(60));
        calendar.set(Calendar.SECOND, random.nextInt(60));


        return calendar;
    }

    private static final String[] PHONE_PREFIX = new String[]{"133", "135", "136", "139", "199", "185"};

    private String getPhone() {
        Random random = new Random();
        int idx = random.nextInt(PHONE_PREFIX.length);
        String prefix = PHONE_PREFIX[idx];

        int i = random.nextInt(100_000_000);
        String phone = prefix + i;
        if (phone.length() < 11) {
            int dur = 11 - phone.length();
            for (int j = 0; j < dur; j++) {
                phone += "0";
            }
        }
        return phone;
    }

    /**
     * 初始化数据
     */
    private void init() throws IOException {
        initNamespace();
        initTable();
    }

    private void initTable() throws IOException {
        Admin admin = connection.getAdmin();
        boolean isExists = admin.tableExists(this.tableName);
        if (!isExists) {
            TableDescriptorBuilder tableDescriptorBuilder = TableDescriptorBuilder.newBuilder(this.tableName);
            tableDescriptorBuilder.setColumnFamily(ColumnFamilyDescriptorBuilder.newBuilder(Bytes.toBytes("base")).build());
            admin.createTable(tableDescriptorBuilder.build());
        }
    }

    private void initNamespace() throws IOException {
        Admin admin = connection.getAdmin();
        try {
            admin.getNamespaceDescriptor(this.namespace);
        } catch (NamespaceNotFoundException e) {
            System.err.println(String.format("%s不存在，创建namespace", this.namespace));
            admin.createNamespace(NamespaceDescriptor.create(this.namespace).build());
        }
    }
}
```

### PhoneLogTest

```java
package org.hadoop.hbase.learn.phone.log;

import org.apache.hadoop.hbase.Cell;
import org.apache.hadoop.hbase.CellUtil;
import org.apache.hadoop.hbase.CompareOperator;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.Filter;
import org.apache.hadoop.hbase.filter.FilterList;
import org.apache.hadoop.hbase.filter.SingleColumnValueFilter;
import org.apache.hadoop.hbase.util.Bytes;
import org.hadoop.learn.phone.log.HBasConnectionHelper;
import org.hadoop.learn.phone.log.PhoneLogInitializor;
import org.junit.Test;

import java.io.IOException;

public class PhoneLogTest {

    private static final String FLAG = "phone_log_test";
    private TableName tableName = TableName.valueOf("phone_log:phone_log");

    @Test
    public void init() throws IOException {
        PhoneLogInitializor initializor = new PhoneLogInitializor("phone_log", "phone_log");
        initializor.randomData();
    }

    /**
     * 查询通话在3月份的所有通话记录
     */
    @Test
    public void query() throws IOException {
        Scan scan = new Scan();
        Filter startFilter = new SingleColumnValueFilter(Bytes.toBytes("base"), Bytes.toBytes("datetime"), CompareOperator.GREATER_OR_EQUAL, Bytes.toBytes("2024-01-01 00:00:00"));
        Filter endFilter = new SingleColumnValueFilter(Bytes.toBytes("base"), Bytes.toBytes("datetime"), CompareOperator.LESS, Bytes.toBytes("2024-06-15 13:07:58"));

        FilterList filterList = new FilterList(startFilter, endFilter);
        scan.setFilter(filterList);

        scan.withStartRow(Bytes.toBytes("13310019762_1711679478875"), true);
        scan.withStopRow(Bytes.toBytes("13310953490_1716287948631"), true);

//        byte[] bases = Bytes.toBytes("base");
//        scan.addColumn(bases, Bytes.toBytes("datetime"));
//        scan.addColumn(bases, Bytes.toBytes("rnum"));
//        scan.addColumn(bases, Bytes.toBytes("snum"));
//        scan.addColumn(bases, Bytes.toBytes("seconds"));

        Connection connection = HBasConnectionHelper.getConnection(FLAG);
        Table table = connection.getTable(this.tableName);
        ResultScanner scanner = table.getScanner(scan);
        this.printResult(scanner);
    }

    private void printResult(ResultScanner scanner) {
        for (Result result : scanner) {
            this.printResult(result);
        }
    }

    private void printResult(Result result) {
        byte[] bases = Bytes.toBytes("base");
        System.out.println(Bytes.toString(result.getRow()) + "\t" +
                Bytes.toString(getBytes(result, bases, "rnum"))
                + "\t" + Bytes.toString(getBytes(result, bases, "snum"))
                + "\t" + Bytes.toString(getBytes(result, bases, "datetime"))
                + "\t" + Bytes.toInt(getBytes(result, bases, "seconds")));
    }

    private static byte[] getBytes(Result result, byte[] bases, String column) {
        Cell cell = result.getColumnLatestCell(bases, Bytes.toBytes(column));
        return CellUtil.cloneValue(cell);
    }
}
```
