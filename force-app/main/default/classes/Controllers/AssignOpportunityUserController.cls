public with sharing class AssignOpportunityUserController {
    @AuraEnabled(cacheable=true)
    public static List<IdNameWrapper> getAssignableUsers() {
        List<IdNameWrapper> results = new List<IdNameWrapper>();
        
        for(User u: [
            SELECT Id, Name 
            FROM User 
            WHERE IsActive = true 
            ORDER BY Name]) {
            results.add(new IdNameWrapper(u.Id, u.Name));
        }
        return results;
    }
    
    
    @AuraEnabled
    public static void assignOpportunityToUser(Id opportunityId, Id userId) {
        if (opportunityId == null || userId == null) {
            throw new AuraHandledException('Opportunity ID and User ID cannot be null.');
        }
        Opportunity opp = [
            SELECT Id, Queue__c 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1];
        
        if (String.isBlank(opp.Queue__c)) {
            throw new AuraHandledException('Cannot assign to user: Opportunity Queue is empty.');
        }
        
        opp.OwnerId = userId;
        opp.Queue__c = null;
        update opp;
    }
    
    public class IdNameWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        
        public IdNameWrapper(Id id, String name) {
            this.Id = id;
            this.Name = name;
        }
    }
}