trigger ProjectTask on Project_Task__c (after insert, after update) {
    ProjectTaskTriggerHandler handler = new ProjectTaskTriggerHandler(Trigger.isExecuting, Trigger.size);
    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
        when AFTER_UPDATE {
            handler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
}