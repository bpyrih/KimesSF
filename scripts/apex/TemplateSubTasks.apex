List<Task> taskList = new List<Task>();
// CCCL TEMPLATE
taskList.add(new Task(Subject = 'LONG REQUEST', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Task(Subject = 'CCCL PLAN AND APP', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Task(Subject = 'CCCL GRADING & DRAINAGE PLAN', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Task(Subject = 'CCCL POOL / SPA SECTIONS', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Task(Subject = 'CCCL CULTURAL ESTIMATES', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Task(Subject = 'BUILDING PERMIT PLAN SET', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Task(Subject = 'AGREEMENTS & BILLING', Template_Name__c = 'CCCL TEMPLATE'));

// V SPEC TEMPLATE
taskList.add(new Task(Subject = 'REVIEW 1', Template_Name__c = 'SPEC TEMPLATE'));
taskList.add(new Task(Subject = 'REVIEW 2', Template_Name__c = 'SPEC TEMPLATE'));
taskList.add(new Task(Subject = 'ANSI', Template_Name__c = 'SPEC TEMPLATE'));
taskList.add(new Task(Subject = 'EMAIL', Template_Name__c = 'SPEC TEMPLATE'));

// 527 DOVER DR S
taskList.add(new Task(Subject = 'REVIEW 1', Template_Name__c = '537 DOVER DR S'));
taskList.add(new Task(Subject = 'REVIEW 2', Template_Name__c = '537 DOVER DR S'));
taskList.add(new Task(Subject = 'ANSI', Template_Name__c = '537 DOVER DR S'));
taskList.add(new Task(Subject = 'EMAIL', Template_Name__c = '537 DOVER DR S'));

// FULL PLAN SET
taskList.add(new Task(Subject = 'DRAFT 1', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Task(Subject = 'DRAFT 2', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Task(Subject = 'DRAFT 3', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Task(Subject = 'EMAIL', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Task(Subject = 'BILLING', Template_Name__c = 'FULL PLAN SET'));

insert taskList;