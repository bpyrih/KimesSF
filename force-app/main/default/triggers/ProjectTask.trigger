trigger ProjectTask on Project_Task__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            ProjectTaskTriggerHandler.afterInsert(Trigger.new, Trigger.newMap);
        }
        when AFTER_UPDATE {
            ProjectTaskTriggerHandler.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
        }
    }
}