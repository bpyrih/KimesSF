public with sharing class AssignOpportunityQueueController {
    
    @AuraEnabled(cacheable=true)
    public static List<Queue__c> getQueues() {
        return [SELECT Id, Name FROM Queue__c ORDER BY Name];
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getOpportunityQueue(Id opportunityId) {
        Opportunity opp = [SELECT Queue__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        return opp.Queue__c;
    }
    
    @AuraEnabled
    public static Id assignQueueToOpportunity(Id opportunityId, Id queueId) {
        if (queueId == null) {
            throw new AuraHandledException('Queue Id cannot be null.');
        }
        try {
            Opportunity opp = new Opportunity(
                Id = opportunityId,
                Queue__c = queueId
                );
            update opp;
            return opp.Queue__c;
        } catch(Exception e) {
            throw new AuraHandledException('Failed to assign queue: ' + e.getMessage());
        }
    }
}