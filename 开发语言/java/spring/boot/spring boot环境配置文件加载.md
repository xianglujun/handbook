# spring boot 环境配置加载原理

spring boot的出现，大大减少了配置文件的数量，我们可以通过代码的方式完成spring的所有配置，在spring boot启动过程中，重要的就是环境变量数据的加载，这些环境变量会成为后面容器启动的关键配置信息，因此主要看下环境配置加载的原理。

## 1. 使用实例

在开始了解配置加载以前，首先以demo的方式实验配置的使用，以及可能存在配置文件之间的配置覆盖。

### 1.1 maven项目搭建

maven的项目结构，还是按照parent-child的方式创建，parent负责jar包的版本管理，这样可以实现版本的统一管理。

#### parent pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>org.spring.cloud.alibaba.learn</groupId>
  <artifactId>spring-cloud-alibaba</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>pom</packaging>

  <name>spring-cloud-alibaba</name>
  <url>http://maven.apache.org</url>


  <modules>
    <module>spring-cloud-alibaba-nacos</module>
  </modules>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>com.alibaba.cloud</groupId>
        <artifactId>spring-cloud-alibaba-dependencies</artifactId>
        <version>2021.0.5.0</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
      <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-dependencies</artifactId>
        <version>2021.0.5</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
      <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-dependencies</artifactId>
        <version>2.6.13</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>
</project>
```

#### child pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.spring.cloud.alibaba.learn</groupId>
    <artifactId>spring-cloud-alibaba</artifactId>
    <version>1.0-SNAPSHOT</version>
    <relativePath>../pom.xml</relativePath>
  </parent>

  <groupId>org.example</groupId>
  <artifactId>spring-cloud-alibaba-nacos</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>jar</packaging>

  <name>spring-cloud-alibaba-nacos</name>
  <url>http://maven.apache.org</url>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>4.13.2</version>
      <scope>test</scope>
    </dependency>

    <dependency>
      <groupId>org.springframework.cloud</groupId>
      <artifactId>spring-cloud-starter-bootstrap</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-autoconfigure</artifactId>
    </dependency>
  </dependencies>
</project>
```

则整体的项目结构如下：

![](../../../../assets/2023-04-07-10-02-18-image.png)

### 1.2 创建配置文件

我们只是单纯的查看配置文件的加载原理，因此不需要太多的配置信息。从上图可以知道，主要包含了三个配置文件：

- bootstrap.yml

- application.yml

- application-dev.yml

这三个文件存在加载顺序的先后关系，按照加载顺序排列。

> bootstrap.yml文件的加载，在spring-boot中是不会加载的，该配置文件是在spring-cloud-bootstrap中引入并加载。

bootstrap.yml的配置如下:

```yml
config:
  name: bootstrap
  bootstrap: app-boot
spring:
  application:
    name: spring-cloud-alibaba-nacos
```

application.yml

```yml
config:
  name: application
  app: application
spring:
  profiles:
    active: dev
```

application-dev.yml

```yml
config:
  name: spplication-dev
```

### 1.3 程序实现

```java
@SpringBootApplication
public class SpringApplicationNacos {
    public static void main(String[] args) {
        ConfigurableApplicationContext applicationContext = SpringApplication.run(SpringApplicationNacos.class, args);
        System.out.println(applicationContext);
        ConfigurableEnvironment environment = applicationContext.getEnvironment();
        System.out.println(environment.getProperty("config.name"));
        System.out.println(environment.getProperty("config.app"));
        System.out.println(environment.getProperty("config.bootstrap"));
    }
}
```

从代码的实现中可以看出，程序还是很简单的，就是创建ApplicationContext并从Environment中获取对应的变量信息。

执行以上代码，可以得到以下输出结果信息：

```textile
spplication-dev
application
app-boot
```

可以看出，相同的配置文件信息，application-dev.yml具有更高的优先级，因此我们以上面这段代码为例，跟踪环境信息加载源码。

## 2. 环境配置加载

### 2.1 SpringApplication

spring boot的启动都是以SpringApplication为入口，通过run()方法发起容器的启动。在SpringApplication类中，主要通过new的方式创建SpringApplication对象，并执行目标run()方法。

![](../../../../assets/2023-04-07-10-22-28-image.png)

最终代码会走到SpringApplication构造器中，构造器中包含了包含了初始化的一些代码逻辑，如下：

```java
	public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
		// 资源加载器
		this.resourceLoader = resourceLoader;
		// 参数必要验证，启动类不能为空
		Assert.notNull(primarySources, "PrimarySources must not be null");
		this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
		// 确定应用类型，主要通过加载特定的class对象判定是否成功，如果成功则为指定类型。
		// 在web中主要包含了Servlet和WebFlux响应式的两种，如果没有引入web包，则为null
		this.webApplicationType = WebApplicationType.deduceFromClasspath();
		// 获取BootstrapRegistryInitializer对象，这里主要通过Spring SPI的方式加载对应的类型
		// 程序会加载所有jar包中的spring.factories的文件中的配置，并缓存
		this.bootstrapRegistryInitializers = new ArrayList<>(
				getSpringFactoriesInstances(BootstrapRegistryInitializer.class));
		// 获取并初始化ApplicationContextInitializer实例
		setInitializers((Collection) getSpringFactoriesInstances(ApplicationContextInitializer.class));
		// 获取并初始化ApplicationListener实例
		setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
		this.mainApplicationClass = deduceMainApplicationClass();
	}
```

#### run()

```java
public ConfigurableApplicationContext run(String... args) {
	long startTime = System.nanoTime();
	// 创建启动上下文
	DefaultBootstrapContext bootstrapContext = createBootstrapContext();
	ConfigurableApplicationContext context = null;
	// 设置系统信息
	configureHeadlessProperty();
	// 获取SpringApplicationRunLister对象，通过SPI从spring.factories中加载
	SpringApplicationRunListeners listeners = getRunListeners(args);
	// 执行starting方法, 通过SpringApplicationRunListeners发送ApplicationStartingEvent事件
	listeners.starting(bootstrapContext, this.mainApplicationClass);
	try {
		// 创建命令行参数对象
		ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
		// 准备Environment对象
		ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);
		configureIgnoreBeanInfo(environment);
		....
	}
	...
	return context;
}
```

在执行环境变量操作之前，主要执行了几个重要的步骤：

- 创建`DefaultBootstrapContext`对象，这个对象主要是上下文，用于存放在执行过程中的一些重要的结果

- 获取`SpringApplicationRunListener`对象，这个对象是对容器开始执行的监听，然后在执行前通过`ApplicationStartingEvent`事件触发。这个对象的扩展，主要通过Spring的SPI机制来完成。

#### prepareEnvironment()

```java
private ConfigurableEnvironment prepareEnvironment(SpringApplicationRunListeners listeners,
			DefaultBootstrapContext bootstrapContext, ApplicationArguments applicationArguments) {
		// 创建或获取Environment对象
		// 该方法会根据webApplicationType创建不同的Environment对象
		// 如果environment对象已经存在，则直接返回
		ConfigurableEnvironment environment = getOrCreateEnvironment();
		// 配置Environment, 
		// 主要包括设置ConversionService对象
		// 合并默认的配置信息以及命令行的配置信息，并将source名称定义为commandLineArgs
		configureEnvironment(environment, applicationArguments.getSourceArgs());
		// 关联Environment对象，
		// 该方法主要判断在环境变量中是否已经包含了configurationProperties的resource信息
		// 如果已经包含，则将该resource方法resources列表的头部，如果不存在，则创建SpringConfigurationPropertySources
		ConfigurationPropertySources.attach(environment);
		// 发送ApplicationEnvironmentPreparedEvent事件，并由监听器执行处理该事件
		// 这里的事件处理机制也是加载各种配置文件的入口地方
		listeners.environmentPrepared(bootstrapContext, environment);
		// 将defaultProperties的配置信息移动到resources末尾，相当于降低优先级
		DefaultPropertiesPropertySource.moveToEnd(environment);
		Assert.state(!environment.containsProperty("spring.main.environment-prefix"),
				"Environment prefix cannot be set via properties.");
		// 将environment和SpringApplication进行绑定
		bindToSpringApplication(environment);

		// 如果是自定义的环境变量，则需要将environment对象转换为StandardEnvironment对象
		if (!this.isCustomEnvironment) {
			environment = convertEnvironment(environment);
		}
		// 将configurationProperties配置放到resources头部
		ConfigurationPropertySources.attach(environment);
		// 返回环境变量对象
		return environment;
	}
```

- configureEnvironment()：该方法主要合并了默认配置信息和命令行的配置信息

- ConfigurationPropertySources.attach()：该方主要是配置configurationProperties的配置员source，并将该配置放在首位，这样具有高优先权

- environmentPrepared()：该方法则是真正加载配置文件的地方，作为重点的对象

### 2.2 SpringApplicationRunListener

该类主要用于执行在Environment对象的对象操作，该类的实现类是通过spring的SPI的机制加载到内存中，即:`spring.factories`文件进行配置，具体配置信息如下：

```properties
# Run Listeners
org.springframework.boot.SpringApplicationRunListener=\
org.springframework.boot.context.event.EventPublishingRunListener
```

> 这里也是作为spring的SPI机制的扩展重点，因为这些扩展点我们也可以通过这种方式加载自己的配置文件源，然后做自定义的实现。

> 另外还有一点很有意思的是，spring并不是直接遍历SpringApplicationRunListener列表，而是通过一个对象SpringApplicationRunListeners来间接的遍历，并提供了Iterator的能力，这种方式可以避免集合的遍历代码分散，实现功能的内敛

在以上的实例中，该对象之引入了一个实例，

![](../../../../assets/2023-04-07-14-57-52-image.png)

也就是`EventPublishingRunListener`对象，该对象也就是处理加载配置文件的入口。

### 2.3 EventPublishingRunListener

我们查看该类的实现接口`SpringApplicationRunListener`, 可以看出，该类就是定义了容器启动中每个阶段不同处理，我们可以根据自己需求，实现每个阶段中的一部分进行扩展。

#### 构造器

```java
	public EventPublishingRunListener(SpringApplication application, String[] args) {
		// 当前正在启动的SpringApplication对象
		this.application = application;
		// 命令行参数
		this.args = args;
		// 事件分发器初始化
		this.initialMulticaster = new SimpleApplicationEventMulticaster();
		// 这里我们知道，在初始化SpringApplication的时候，是从spring.factories中
		// 加载了配置的ApplicationListener实现实例，因此从application中获取并和
		// 事件分发器进行绑定
		for (ApplicationListener<?> listener : application.getListeners()) {
			this.initialMulticaster.addApplicationListener(listener);
		}
	}
```

#### environmentPrepared()

该方法就是用来处理环境environment准备的入口，具体代码如下：

```java
	public void environmentPrepared(ConfigurableBootstrapContext bootstrapContext,
			ConfigurableEnvironment environment) {
		this.initialMulticaster.multicastEvent(
				new ApplicationEnvironmentPreparedEvent(bootstrapContext, this.application, this.args, environment));
	}
```

这个方法就很简单了，主要分为两步：

- 创建ApplicationEnvironmentPreparedEvent事件对象

- 分发该事件到ApplicationListener示例并进行处理。

### 2.4 SimpleApplicationEventMulticaster

在执行事件分发的时候，对应的ApplicationListener实际上已经实例化完成，可以通过堆栈查看对应的列表：

![](../../../../assets/2023-04-07-15-11-47-image.png)

在默认的配置下，有11个ApplicationListener被加载，对于事件的分发，并不是所有的Listener都可以执行，因此在具体的分发的时候，需要过滤掉不能处理的listener.

#### multicaseEvent()

该方法则是具体执行事件分发的地方，具体代码如下：

```java
public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
	// 解析泛型，主要获取event的实际类型
	ResolvableType type = (eventType != null ? eventType : resolveDefaultEventType(event));
	// 获取线程池对象，如果没有开启异步事件分发，则为null
	Executor executor = getTaskExecutor();
	// getApplicationListeners()方法主要根据event的实际类型判断，
	// listener是否能够处理当前event, 如果能，则返回; 否则过滤掉
	for (ApplicationListener<?> listener : getApplicationListeners(event, type)) {
		// 如果线程池对象不为空，则异步执行事件分发
		if (executor != null) {
			executor.execute(() -> invokeListener(listener, event));
		}
		else {
			// 否则同步执行分发
			invokeListener(listener, event);
		}
	}
}
```

![](../../../../assets/2023-04-07-15-16-36-image.png)

通过事件类型过滤后，实际上只有8个listener能够处理当前的事件。具体处理逻辑，可以自行查看对应源码。

#### doInvokeListener()

```java
private void doInvokeListener(ApplicationListener listener, ApplicationEvent event) {
	try {
		listener.onApplicationEvent(event);
	}
	catch (ClassCastException ex) {
		....
	}
}
```

执行listener就只是调用对应的onApplicaiontEvent()方法。

### 2.5 ApplicationListener

该类就是具体处理以上各种事件的入口，对于配置文件二院，我们不需要关心所有的类，而是只关注配置文件相关的类即可。因此，在一下的源码梳理中，不会列出所有类的实现。

#### 2.5.1 BootstrapApplicationListener

> 该类不是spring-boot引入，而是由spring-cloud引入。因此这里需要区分，当我们只使用spring-boot时，是没有这个类型的。

##### onApplicationEvent()

```java
public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
	// 获取环境对象
	ConfigurableEnvironment environment = event.getEnvironment();

	// bootstrapEnabled: 主要判断是否启用bootstrap, 可以通过判断spring.cloud.bootstrap.enabled=true或org.springframework.cloud.bootstrap.marker.Marker
	// 能够被加载，因此就算不开启配置，只要引入了spring-cloud-bootstrap包，也就默认配置的开启
	// useLegacyProcessing()方法用于判断spring.config.use-legacy-processing是否为true
	if (!bootstrapEnabled(environment) && !useLegacyProcessing(environment)) {
		return;
	}
	// don't listen to events in a bootstrap context
	// 判断是否包含了bootstrap的配置员，主要是为防止循环监听和加载
	if (environment.getPropertySources().contains(BOOTSTRAP_PROPERTY_SOURCE_NAME)) {
		return;
	}

	ConfigurableApplicationContext context = null;
	// 这里是获取spring.cloud.bootstrap.name的值，默认只为bootstrap.
	// 这里需要注意，这个时候，环境配置中只包含了环境变量和系统变量以及命令行参数，因此这个配置如果需要
	// 该表该值，是不可以通过配置文件进行修改，或者定义更高级别的处理方式
	String configName = environment.resolvePlaceholders("${spring.cloud.bootstrap.name:bootstrap}");

	// 这里是容器初始代码，这个代码也是在初始化SpringApplication时通过SPI的方式加载
	// 这段代码主要是获取ApplicationContext容器，如果是具有层级关系的初始化器时，则尝试
	// 从初始化器中获取ApplicationContext容器
	for (ApplicationContextInitializer<?> initializer : event.getSpringApplication().getInitializers()) {
		if (initializer instanceof ParentContextApplicationContextInitializer) {
			context = findBootstrapContext((ParentContextApplicationContextInitializer) initializer, configName);
		}
	}

	// 如果ApplicationContext容器化没有创建，则创建
	if (context == null) {
		context = bootstrapServiceContext(environment, event.getSpringApplication(), configName);
		event.getSpringApplication().addListeners(new CloseContextOnFailureApplicationListener(context));
	}

	apply(context, event.getSpringApplication(), environment);
}
```

在该方法中主要有以下步骤：

- 环境配置中是否已经加入了bootstrap源，如果包含了，则不再重复加载

- 是否已经创建ApplicationContext上下文，如果没有包含，则创建ApplicaontContext上下文，并重新执行SpringApplication.run()方法

##### bootstrapServiceContext()

```java
private ConfigurableApplicationContext bootstrapServiceContext(ConfigurableEnvironment environment,
			final SpringApplication application, String configName) {
		ConfigurableEnvironment bootstrapEnvironment = new AbstractEnvironment() {
		};

		// 获取配置源列表
		MutablePropertySources bootstrapProperties = bootstrapEnvironment.getPropertySources();
		// 获取bootstrap配置文件列表
		String configLocation = environment.resolvePlaceholders("${spring.cloud.bootstrap.location:}");
		// 获取bootstrap额外配置信息
		String configAdditionalLocation = environment
				.resolvePlaceholders("${spring.cloud.bootstrap.additional-location:}");
		
		// 创建bootstrap配置映射
		Map<String, Object> bootstrapMap = new HashMap<>();
		// 设置spring.config.name配置为bootstrap
		bootstrapMap.put("spring.config.name", configName);
		bootstrapMap.put("spring.main.web-application-type", "none");
		if (StringUtils.hasText(configLocation)) {
			bootstrapMap.put("spring.config.location", configLocation);
		}
		if (StringUtils.hasText(configAdditionalLocation)) {
			bootstrapMap.put("spring.config.additional-location", configAdditionalLocation);
		}
		// 加入bootstrap配置信息
		bootstrapProperties.addFirst(new MapPropertySource(BOOTSTRAP_PROPERTY_SOURCE_NAME, bootstrapMap));
		// 从已有environment中读取源数据并加入到新的environment中
		for (PropertySource<?> source : environment.getPropertySources()) {
			if (source instanceof StubPropertySource) {
				continue;
			}
			bootstrapProperties.addLast(source);
		}

		// 构建SpringApplicaionBuilder对象
		SpringApplicationBuilder builder = new SpringApplicationBuilder().profiles(environment.getActiveProfiles())
				.bannerMode(Mode.OFF).environment(bootstrapEnvironment)
				.registerShutdownHook(false).logStartupInfo(false).web(WebApplicationType.NONE);
		final SpringApplication builderApplication = builder.application();
		
		// 如果启动class为空，则使用当前application的主class
		if (builderApplication.getMainApplicationClass() == null) {
			builder.main(application.getMainApplicationClass());
		}

		// 如果包含refreshArgs配置源，则过滤listener
		if (environment.getPropertySources().contains("refreshArgs")) {
			builderApplication.setListeners(filterListeners(builderApplication.getListeners()));
		}

		// configuration源设置
		builder.sources(BootstrapImportSelectorConfiguration.class);
		// 执行run方法，跟SpringApplication.run()方法类似，只是很多参数设置为固定值
		// 这个时候实际上创建了一个新的ApplicationContext对象
		final ConfigurableApplicationContext context = builder.run();
		// 设置当前ApplicationContext的id为bootstrap
		context.setId("bootstrap");
		// 为AncestorInitializer对象设置parent的容器信息
		addAncestorInitializer(application, context);
		// 从配置源中移除bootstrap配置信息
		bootstrapProperties.remove(BOOTSTRAP_PROPERTY_SOURCE_NAME);
		// 合并配置
		mergeDefaultProperties(environment.getPropertySources(), bootstrapProperties);
		return context;
	}
```

#### 2.5.2 EnvironmentPostProcessorApplicationListener

该监听器主要用于处理EnvironmentPostProcessor的实现，具体加载代码如下：

```java
	static EnvironmentPostProcessorsFactory fromSpringFactories(ClassLoader classLoader) {
		return new ReflectionEnvironmentPostProcessorsFactory(classLoader,
				SpringFactoriesLoader.loadFactoryNames(EnvironmentPostProcessor.class, classLoader));
	}
```

可以看出，EnvironmentPostProcessor的执行通过SPI机制进行加载，具体在spring.factories的定义如下：

```properties
# Environment Post Processors
org.springframework.boot.env.EnvironmentPostProcessor=\
org.springframework.boot.cloud.CloudFoundryVcapEnvironmentPostProcessor,\
org.springframework.boot.context.config.ConfigDataEnvironmentPostProcessor,\
org.springframework.boot.env.RandomValuePropertySourceEnvironmentPostProcessor,\
org.springframework.boot.env.SpringApplicationJsonEnvironmentPostProcessor,\
org.springframework.boot.env.SystemEnvironmentPropertySourceEnvironmentPostProcessor,\
org.springframework.boot.reactor.DebugAgentEnvironmentPostProcessor
```

> 这里的定义只是取了其中很小的一部分，并不是全部内容，只是为了说明配置方式。

##### onApplicationEvent()

事件的执行入口方法，该方法很简单，

```java
public void onApplicationEvent(ApplicationEvent event) {
	if (event instanceof ApplicationEnvironmentPreparedEvent) {
		onApplicationEnvironmentPreparedEvent((ApplicationEnvironmentPreparedEvent) event);
	}
	if (event instanceof ApplicationPreparedEvent) {
		onApplicationPreparedEvent();
	}
	if (event instanceof ApplicationFailedEvent) {
		onApplicationFailedEvent();
	}
}
```

该类能够处理多种事件类型，在该阶段主要关心`ApplicationEnvironmentPreparedEvent`即可

##### onApplicationEnvironmentPreparedEvent()

```java
private void onApplicationEnvironmentPreparedEvent(ApplicationEnvironmentPreparedEvent event) {
	// 获取环境变量对象
	ConfigurableEnvironment environment = event.getEnvironment();
	// 获取SpringApplication对象
	SpringApplication application = event.getSpringApplication();
	// 获取EnvironmentPostProcessor列表
	for (EnvironmentPostProcessor postProcessor : getEnvironmentPostProcessors(application.getResourceLoader(),
			event.getBootstrapContext())) {
		// 遍历并同步调用方法
		postProcessor.postProcessEnvironment(environment, application);
	}
}
```

该方法主要包含了两个重要的点：

- 从`spring.factories`中获取`EnvironmentPostProcessor`对象列表，主要通过SPI机制继续加载

- 调用`EnvironmentPostProcessor.postProcessEnvironment()`方法

### 2.6 EnvironmentPostProcessor

该类是对Environment对象的后置处理器，该接口定义也很简单：

```java
public interface EnvironmentPostProcessor {
	void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application);
}
```

在以上配置中，可以查看从spring.factories中加了处理器列表：

#### 2.6.1 ConfigDataEnvironmentPostProcessor

配置文件数据处理器，在该处理器中会主要处理配置文件相关的加载.

```java
void postProcessEnvironment(ConfigurableEnvironment environment, ResourceLoader resourceLoader,
			Collection<String> additionalProfiles) {
		try {
			this.logger.trace("Post-processing environment to add config data");
			// 获取ResourceLoader对象
			resourceLoader = (resourceLoader != null) ? resourceLoader : new DefaultResourceLoader();
			// 获取ConfigDataEnvironment对象，并调用processAndApply()方法
			getConfigDataEnvironment(environment, resourceLoader, additionalProfiles).processAndApply();
		}
		catch (UseLegacyConfigProcessingException ex) {
			...
		}
	}

	ConfigDataEnvironment getConfigDataEnvironment(ConfigurableEnvironment environment, ResourceLoader resourceLoader,
			Collection<String> additionalProfiles) {
		// 创建爱你ConfigDataEnvironment对象
		return new ConfigDataEnvironment(this.logFactory, this.bootstrapContext, environment, resourceLoader,
				additionalProfiles, this.environmentUpdateListener);
	}
```

对于环境配置处理，最终委派到了`ConfigDataEnvironment`对象中，因此我们需要主要查看该对象内部的处理逻辑。

## 2.7 ConfigDataEnvironment

该类需要关注类型初始化的逻辑，其中包含了多的潜在的逻辑，对后续阅读会有很大的帮助。

### 类初始化

类初始化主要是为了初始化静态变量相关数据，在该类中，静态初始化主要定义了扫描的配置文件路径信息。

```java
	static final ConfigDataLocation[] DEFAULT_SEARCH_LOCATIONS;
	static {
		List<ConfigDataLocation> locations = new ArrayList<>();
		locations.add(ConfigDataLocation.of("optional:classpath:/;optional:classpath:/config/"));
		locations.add(ConfigDataLocation.of("optional:file:./;optional:file:./config/;optional:file:./config/*/"));
		DEFAULT_SEARCH_LOCATIONS = locations.toArray(new ConfigDataLocation[0]);
	}
```

这里的配置文件的路径包含了两种：

- 在`classpath`下寻找配置文件
  
  - `/`
  
  - `/config/`

- 在当前路径下寻找
  
  - `./`
  
  - `./config/`
  
  - `./config/*/`

> 相比之下，在当前路径下寻找多了一个正则匹配的项，因此扫描的路径更广
