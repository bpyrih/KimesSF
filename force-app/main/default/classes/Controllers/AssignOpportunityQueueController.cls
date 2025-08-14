public with sharing class AssignOpportunityQueueController {
    @AuraEnabled(cacheable=true)
    public static List<IdNameWrapper> getQueues() {
        List<IdNameWrapper> results = new List<IdNameWrapper>();
        
        for (Group g : [
            SELECT Id, Name 
            FROM Group 
            WHERE Type = 'Queue' 
            ORDER BY Name
        ]) {
            results.add(new IdNameWrapper(g.Id, g.Name));
        }
        
        return results;
    }
    
    @AuraEnabled
    public static void assignQueueToOpportunity(Id opportunityId, Id queueId) {
        Opportunity opp = [
            SELECT Id, Queue__c 
            FROM Opportunity 
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        opp.Queue__c = queueId;
        update opp;
    }
    
    public class IdNameWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        public IdNameWrapper(String id, String name) {
            this.id = id;
            this.name = name;
        }
    }
}
