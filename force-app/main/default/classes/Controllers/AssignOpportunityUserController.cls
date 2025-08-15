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
            Opportunity opp = new Opportunity(
                Id = opportunityId,
                OwnerId = userId,
                Queue__c = null // Clear the queue if assigning to a user  
            );
            update opp;
    }

    public class IdNameWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String Name;

        public IdNameWrapper(Id id, String name) {
            this.id = id;
            this.Name = name;
        }
    }
}