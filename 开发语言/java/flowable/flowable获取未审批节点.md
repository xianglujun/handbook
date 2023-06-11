# flowable获取未审批节点列表

在最近的项目开发中，有一个需求为获取未审批节点的信息。在我们系统中，流程图没有特别的节点，主要包含了并行网关、排他网关、任务节点这几种类型的节点。因此在获取未审批节点的时候，就没有其他的业务处理逻辑。该问题作为记录，以便日后使用。

## 排他网关

在处理逻辑中，比较复杂的应该就是排他网关了。在排他网关的时候，是需要根据表达式计算行走的路径，直接影响了获取后续列表。因此我们可以定义一个工具类，用于计算表达式的具体值。

```java
@UtilityClass
public class ExpressionUtil {

	/**
	 * 计算表达式结果值
	 *
	 * @param expression 表达式信息
	 * @param variables  参与计算的变量
	 * @return 表达式结果
	 */
	public Object evalExpression(String expression, Map<String, Object> variables) {
		DelegateExecution execution = new ExecutionEntityImpl();
		if (Objects.nonNull(variables)) {
			variables.entrySet()
					.forEach(entry -> {
						execution.setTransientVariable(entry.getKey(), entry.getValue());
					});
		}

		// 执行表达式
		return evalExpression(expression, execution);
	}

	/**
	 * 获取表达式计算值
	 *
	 * @param expression 表达式
	 * @param execution  执行容器
	 * @return 执行结果
	 */
	public Object evalExpression(String expression, DelegateExecution execution) {
		// 获取系统内置的ExpressionManager
		ExpressionManager expressionManager = SpringUtils.getBean(ExpressionManager.class);
		Expression evalExpression = expressionManager.createExpression(expression);
		return evalExpression.getValue(execution);
	}

	/**
	 * 判断条件表达式
	 *
	 * @param expression 表达式字符串
	 * @param variables  参与计算的变量
	 * @return 返回结果
	 */
	public boolean conditionExpression(String expression, Map<String, Object> variables) {
		Object val = evalExpression(expression, variables);
		if (val instanceof Boolean) {
			return (Boolean) val;
		}

		return false;
	}

	public static boolean isExpression(String expression) {
		return StringUtils.isNotBlank(expression)
				&& expression.indexOf("${") > -1;
	}
}
```

在上面的表达式中，主要使用了`ExpressionManager`来根据表达式创建`Expression`对象，该对象需要使用flowable自动创建的对象，因为flowable中部分语法属于扩展，如果自己创建，可能会导致语法的不支持。但是在flowable中，默认`ExpressionManager`对象并没有暴露在spring容器中，因此需要将该对象暴露到spring容器中，则对应的配置对象如下:

## configuration

```java
@Slf4j
@Configuration
public class WorkflowConfiguration {

	@Bean
	public ExpressionManager expressionManager(ProcessEngine processEngine) {
		ProcessEngineConfiguration configuration = processEngine.getProcessEngineConfiguration();
		if (configuration instanceof HasExpressionManagerEngineConfiguration) {
			return ((HasExpressionManagerEngineConfiguration) configuration).getExpressionManager();
		}

		log.info("未找到ExpressionManager实例对象，则默认创建");
		DelegateInterceptor delegateInterceptor = new DefaultDelegateInterceptor();
		Map<Object, Object> beans = new HashMap<>();
		ExpressionManager expressionManager = new ProcessExpressionManager(delegateInterceptor, beans);
		return expressionManager;
	}
}
```

## FlowableUtil

在有了以上的基础配置之后，则我们就可以开始获取未审批的节点元素列表了，具体实现如下:

```java
/**
	 * 获取当前运行节点之后的未执行节点, 只关心用户任务
	 *
	 * @param processingTaskKeys 正在执行任务列表
	 * @param finishedTaskKeys   已完成任务列表
	 * @param bpmnModel          流程定义
	 * @return 后续未执行节点
	 */
	public static List<UserTask> listNextFlowElement(List<String> processingTaskKeys,
													 List<String> finishedTaskKeys,
													 BpmnModel bpmnModel,
													 Map<String, Object> variables) {
		processingTaskKeys = Objects.isNull(processingTaskKeys) ? new ArrayList<>() : processingTaskKeys;
		finishedTaskKeys = Objects.isNull(finishedTaskKeys) ? new ArrayList<>() : finishedTaskKeys;
		variables = Objects.isNull(variables) ? new HashMap<>() : variables;

		List<UserTask> processingTasks = new ArrayList<>();
		List<FlowElement> allElements = new ArrayList<>();
		FlowableUtils.getAllElements(bpmnModel.getProcesses().get(0).getFlowElements(), allElements);

		// 获取正在执行的任务节点
		List<String> finalProcessingTaskKeys = processingTaskKeys;
		allElements.forEach(element -> {
			if (finalProcessingTaskKeys.contains(element.getId())) {
				processingTasks.add((UserTask) element);
			}
		});

		List<UserTask> flowElements = new ArrayList<>();
		List<String> finishedTasks = new ArrayList<>(finishedTaskKeys);
		// 更具当前正在执行的任务定位下一个节点任务
		if (CollectionUtil.isNotEmpty(processingTasks)) {
			Map<String, Object> finalVariables = variables;
			processingTasks.forEach(userTask -> {
				listNextFlowElement(userTask, flowElements, finalVariables, finishedTasks);
			});
		}

		return flowElements;
	}

	/**
	 * 获取当前节点的下一个节点
	 *
	 * @param flowElement 流程节点
	 * @param result      返回结果集
	 * @param variables   参数变量列表
	 */
	private static void listNextFlowElement(FlowElement flowElement,
											List<UserTask> result,
											Map<String, Object> variables,
											List<String> finishedTaskKeys) {
		// 结束条件
		if (flowElement instanceof EndEvent) {
			log.info("当前线路流程已经遍历到终点, 停止遍历...");
			return;
		}

		List<FlowElement> outgoingFlows = new ArrayList<>();
		if (flowElement instanceof ExclusiveGateway) {
			// 排他网关
			ExclusiveGateway gateway = (ExclusiveGateway) flowElement;
			List<SequenceFlow> outgoings = gateway.getOutgoingFlows();
			// 根据线的条件判断输出路线
			if (CollectionUtil.isNotEmpty(outgoings)) {
				for (SequenceFlow sequenceFlow : outgoings) {
					// 获取线上的表达式信息
					String expression = sequenceFlow.getConditionExpression();
					if (StringUtils.isBlank(expression)) {
						outgoingFlows.add(sequenceFlow.getTargetFlowElement());
						return;
					}
					// 执行表达式
					boolean conVal = ExpressionUtil.conditionExpression(expression, variables);
					if (conVal) {
						outgoingFlows.add(sequenceFlow.getTargetFlowElement());
						break;
					}
				}
			}
		} else if (flowElement instanceof FlowNode) {
			// 并行网关
			FlowNode flowNode = (FlowNode) flowElement;
			List<SequenceFlow> sequenceFlows = flowNode.getOutgoingFlows();
			if (CollectionUtil.isNotEmpty(sequenceFlows)) {
				sequenceFlows.forEach(sequenceFlow -> {
					FlowElement element = sequenceFlow.getTargetFlowElement();
					outgoingFlows.add(element);
				});
			}
		}

		if (CollectionUtil.isNotEmpty(outgoingFlows)) {
			outgoingFlows.forEach(outgoingFlow -> {

				boolean hasCycle = finishedTaskKeys.contains(outgoingFlow.getId());

				if (hasCycle) {
					log.info("流程产生循环, 停止继续向后遍历, 任务key: {}", outgoingFlow.getId());
					return;
				}

				if (outgoingFlow instanceof UserTask) {
					result.add((UserTask) outgoingFlow);
				}
				finishedTaskKeys.add(outgoingFlow.getId());
				listNextFlowElement(outgoingFlow, result, variables, finishedTaskKeys);
			});
		}

	}
```

在以上的实现中，包含了几个特别重要的参数：

- processingTaskKeys: 该参数主要是传入流程中正在执行的任务列表，我们可以根据正在执行的任务列表定位到当前流程所处的节点，然后从当前节点向后遍历。

- finishedTaskKeys: 该参数主要传入已经审批完成的任务key和已经遍历过的任务key, 这是因为，当流程配置异常的情况下，可能会配置循环的流程，因此当流程产生循环的时候就需要及时的跳出，防止进入死循环。同时当我们使用排他网关或者并行网关的时候，因为线条有分叉也有合并，因此在合并的时候，只需要处理一次即可。

- bpmnModel: 该对象则是流程定义的xml文件对象，其中包含了对流程的解析

- variables: 则是流程中已经产生的全局的变量，该变量会在解析排他网关的时候产生作用

## 获取流程详情列表

```java
public List<WfTaskVo> queryDetailProcess(String procInsId, boolean filterFinished, boolean hasNext) {
		if (StringUtils.isNotBlank(procInsId)) {
			log.info("queryDetailProcess: 开始处理流程节点列表, 流程实例编号: {}", procInsId);
			Stopwatch outStopwatch = Stopwatch.createStarted();
			List<HistoricTaskInstance> taskInstanceList = historyService.createHistoricTaskInstanceQuery()
					.processInstanceId(procInsId)
					.taskWithoutDeleteReason()
					.orderByHistoricTaskInstanceStartTime().desc()
					.list();
			List<Comment> commentList = taskService.getProcessInstanceComments(procInsId);
			List<WfTaskVo> taskVoList = new ArrayList<>(taskInstanceList.size());

			List<String> processTaskKeys = new ArrayList<>();
			List<String> finishedTaskKeys = new ArrayList<>();

			processTaskInfo(taskInstanceList, commentList, taskVoList, processTaskKeys, finishedTaskKeys, filterFinished);

			if (hasNext && CollectionUtil.isNotEmpty(processTaskKeys)) {
				String procDefId = taskInstanceList.get(0).getProcessDefinitionId();
				log.info("queryDetailProcess: 开始处理审批流程后续节点, 流程实例: {}", procInsId);
				Stopwatch stopwatch = Stopwatch.createStarted();
				List<WfTaskVo> wfTaskVos = handleNextFlows(procInsId, procDefId, processTaskKeys, finishedTaskKeys);
				if (CollectionUtil.isNotEmpty(wfTaskVos)) {
					CollectionUtil.reverse(wfTaskVos);
					taskVoList.addAll(0, wfTaskVos);
				}
				log.info("queryDetailProcess: 处理审批流程后续节点完成, 流程实例: {}, 用时: {}ms", procInsId, stopwatch.stop().elapsed(TimeUnit.MILLISECONDS));
			}

			log.info("queryDetailProcess: 获取流程节点成功，实例编号: {}, 用时: {}ms", procInsId, outStopwatch.stop().elapsed(TimeUnit.MILLISECONDS));
			return taskVoList;
		}
		return Collections.emptyList();
	}

	/**
	 * 获取未开始任务节点
	 *
	 * @param procInsId        流程实例编号
	 * @param procDefId        流程定义编号
	 * @param processTaskKeys  正在处理的任务编号
	 * @param finishedTaskKeys 已完成任务编号
	 * @return 任务详情信息
	 */
	private List<WfTaskVo> handleNextFlows(String procInsId, String procDefId, List<String> processTaskKeys, List<String> finishedTaskKeys) {
		// 查询变量列表
		List<HistoricVariableInstance> variableInstances = historyService.createHistoricVariableInstanceQuery()
				.processInstanceId(procInsId)
				.list();

		Map<String, Object> variables = new HashMap<>();
		variableInstances.forEach(variable -> {
			variables.put(variable.getVariableName(), variable.getValue());
		});

		// 查询流程定义
		BpmnModel bpmnModel = repositoryService.getBpmnModel(procDefId);
		if (Objects.isNull(bpmnModel)) {
			log.warn("handleNextFlows: 未查询到流程定义信息, 流程实例: {}, 流程定义: {}", procInsId, procDefId);
			return Collections.emptyList();
		}

		// 获取流程后续节点
		List<UserTask> userTasks = FlowableUtils.listNextFlowElement(processTaskKeys, finishedTaskKeys, bpmnModel, variables);
		if (CollectionUtil.isEmpty(userTasks)) {
			log.info("handleNextFlows: 未查询到后续节点, 跳过后续步骤。 流程实例: {}", procInsId);
			return Collections.emptyList();
		}

		WfTaskDetermineBuilder determineBuilder = new WfTaskDetermineBuilder.Builder()
				.processDataTypeService(processDataTypeService)
				.variables(variables)
				.build();

		// 开始处理后续节点
		return userTasks.stream()
				.map(determineBuilder::build)
				.map(vo -> {
					vo.setProcInsId(procInsId);
					vo.setProcDefId(procDefId);
					return vo;
				})
				.filter(Objects::nonNull)
				.collect(Collectors.toList());
	}

	private void processTaskInfo(
			List<HistoricTaskInstance> taskInstanceList,
			List<Comment> commentList,
			List<WfTaskVo> taskVoList,
			List<String> processingTaskKeys,
			List<String> finishedTaskKeys,
			boolean filterFinishedTask) {
		taskInstanceList.forEach(taskInstance -> {

			if (filterFinishedTask && Objects.nonNull(taskInstance.getEndTime())) {
				return;
			}

			WfTaskVo taskVo = new WfTaskVo();
			taskVo.setProcDefId(taskInstance.getProcessDefinitionId());
			taskVo.setTaskId(taskInstance.getId());
			taskVo.setTaskDefKey(taskInstance.getTaskDefinitionKey());
			taskVo.setTaskName(taskInstance.getName());
			taskVo.setCreateTime(taskInstance.getCreateTime());
			taskVo.setFinishTime(taskInstance.getEndTime());

			if (Objects.nonNull(taskInstance.getEndTime())) {
				finishedTaskKeys.add(taskInstance.getTaskDefinitionKey());
			} else {
				processingTaskKeys.add(taskInstance.getTaskDefinitionKey());
			}

			boolean isGroup = false;
			if (StringUtils.isNotBlank(taskInstance.getAssignee())) {
				Long userId = Long.parseLong(taskInstance.getAssignee());
				UcUserVO user = userService.getUserById(userId);

				String nickName = user.getNickName();
				nickName = StringUtils.isBlank(nickName) ? user.getName() : nickName;
				taskVo.setAssigneeId(user.getId());
				taskVo.setAssigneeName(nickName);
				taskVo.setDeptName(user.getDepartmentName());
				taskVo.setAssigneePosition(user.getPositionName());
			}
			// 展示审批人员
			List<HistoricIdentityLink> linksForTask = historyService.getHistoricIdentityLinksForTask(taskInstance.getId());
			StringBuilder stringBuilder = new StringBuilder();
			List<String> groupIds = new ArrayList<>();
			for (HistoricIdentityLink identityLink : linksForTask) {
				if ("candidate".equals(identityLink.getType())) {
					if (StringUtils.isNotBlank(identityLink.getUserId())) {
						Long userId = Long.parseLong(identityLink.getUserId());
						UcUserVO user = userService.getUserById(userId);
						stringBuilder.append(user.getNickName()).append(",");
					}
					if (StringUtils.isNotBlank(identityLink.getGroupId())) {
						groupIds.add(identityLink.getGroupId());
						isGroup = true;
					}
				}
			}

			if (CollectionUtil.isNotEmpty(groupIds)) {
				String candidateNames = processDataTypeService.listDataDesc(groupIds);
				stringBuilder.append(candidateNames);
			}

			if (StringUtils.isNotBlank(stringBuilder)) {
				taskVo.setCandidate(stringBuilder.substring(0, stringBuilder.length() - 1));
			} else {
				taskVo.setCandidate(taskVo.getAssigneeName());
			}

			if (ObjectUtil.isNotNull(taskInstance.getDurationInMillis())) {
				taskVo.setDuration(DateUtil.formatBetween(taskInstance.getDurationInMillis(), BetweenFormatter.Level.SECOND));
			}

			// 新增审批人是否分组标识
			taskVo.setIsGroup(isGroup);
			// 获取意见评论内容
			if (CollUtil.isNotEmpty(commentList)) {
				List<Comment> comments = new ArrayList<>();
				// commentList.stream().filter(comment -> taskInstance.getId().equals(comment.getTaskId())).collect(Collectors.toList());
				for (Comment comment : commentList) {
					if (comment.getTaskId().equals(taskInstance.getId())) {
						comments.add(comment);
						// taskVo.setComment(WfCommentDto.builder().type(comment.getType()).comment(comment.getFullMessage()).build());
					}
				}
				taskVo.setCommentList(comments);
			}

			taskVoList.add(taskVo);
		});
	}
```

> 在我的处理逻辑中我是必须要有已审批的节点的，这个是跟我们自身的业务逻辑来定的，这里的逻辑可以根据不同的需要做调整。

以上就是获取流程未审批节点的处理方式，能够处理简单的流程逻辑，提供了一个大概的思路。有什么问题，欢迎在评论区留言讨论。
