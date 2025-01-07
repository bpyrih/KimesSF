trigger DocumentSignElementTrigger on Document_Sign_Element__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        DocumentSignElementTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        DocumentSignElementTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        DocumentSignElementTriggerHandler.afterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        DocumentSignElementTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}