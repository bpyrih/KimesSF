List<Project_Task__c> taskList = new List<Project_Task__c>();
// CCCL TEMPLATE
taskList.add(new Project_Task__c(Name = 'LONG REQUEST', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'CCCL PLAN AND APP', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'CCCL GRADING & DRAINAGE PLAN', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'CCCL POOL / SPA SECTIONS', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'CCCL CULTURAL ESTIMATES', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'BUILDING PERMIT PLAN SET', Template_Name__c = 'CCCL TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'AGREEMENTS & BILLING', Template_Name__c = 'CCCL TEMPLATE'));

// V SPEC TEMPLATE
taskList.add(new Project_Task__c(Name = 'REVIEW 1', Template_Name__c = 'SPEC TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'REVIEW 2', Template_Name__c = 'SPEC TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'ANSI', Template_Name__c = 'SPEC TEMPLATE'));
taskList.add(new Project_Task__c(Name = 'EMAIL', Template_Name__c = 'SPEC TEMPLATE'));

// 527 DOVER DR S
taskList.add(new Project_Task__c(Name = 'REVIEW 1', Template_Name__c = '537 DOVER DR S'));
taskList.add(new Project_Task__c(Name = 'REVIEW 2', Template_Name__c = '537 DOVER DR S'));
taskList.add(new Project_Task__c(Name = 'ANSI', Template_Name__c = '537 DOVER DR S'));
taskList.add(new Project_Task__c(Name = 'EMAIL', Template_Name__c = '537 DOVER DR S'));

// FULL PLAN SET
taskList.add(new Project_Task__c(Name = 'DRAFT 1', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Project_Task__c(Name = 'DRAFT 2', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Project_Task__c(Name = 'DRAFT 3', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Project_Task__c(Name = 'EMAIL', Template_Name__c = 'FULL PLAN SET'));
taskList.add(new Project_Task__c(Name = 'BILLING', Template_Name__c = 'FULL PLAN SET'));

insert taskList;