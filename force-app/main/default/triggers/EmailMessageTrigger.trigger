trigger EmailMessageTrigger on EmailMessage (after insert) {
    Set<Id> caseIdsToUpdate = new Set<Id>();
    Map<Id, String> caseIdToNewStatus = new Map<Id, String>();
    Map<Id, EmailMessage> caseIdToEmailMessage = new Map<Id, EmailMessage>();
    
    for (EmailMessage email : Trigger.new) {
        if (email.ParentId != null && email.ParentId.getSObjectType() == Case.SObjectType) {
            caseIdsToUpdate.add(email.ParentId);
            caseIdToEmailMessage.put(email.ParentId, email);
        }
    }
    if (caseIdsToUpdate.isEmpty()) {
        return;
    }
    
    List<Case> cases = [SELECT Id, Status, OwnerId FROM Case WHERE Id IN :caseIdsToUpdate];
    Group intakeQueue = [SELECT Id FROM Group WHERE Name = 'Intake' AND Type = 'Queue' LIMIT 1];
    
    Id intakeQueueId = intakeQueue.Id;
    
    for (Case c : cases) {
        EmailMessage email = caseIdToEmailMessage.get(c.Id);
        String newStatusValue = null;
        if (email.Incoming == true) {
            c.Client_Reply_DateTime__c = System.now();
            if (c.Status == 'Closed') {
                newStatusValue = 'Client Replied';
                c.OwnerId= intakeQueueId;
            } else {
                newStatusValue = 'Client Replied';
            }
        } else {
            c.Client_Follow_Up_DateTime__c = System.now();
            newStatusValue = 'Agent Replied/Follow Up';
        }
        
        if (newStatusValue != null && c.Status != newStatusValue) {
            c.Status = newStatusValue;
            caseIdToNewStatus.put(c.Id, newStatusValue);
        }
    }
    
    if (!caseIdToNewStatus.isEmpty()) {
        update cases;
    }
}