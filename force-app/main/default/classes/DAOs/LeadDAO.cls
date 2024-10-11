public with sharing class LeadDAO {
    public List<Lead> getLeadsById(Set<Id> leadIds) {
        return [
            SELECT Id, Request_Type__c, Email
            FROM Lead 
            WHERE Id IN :leadIds
        ];
    }

    public Lead getLeadById(Id leadId) {
        List<Lead> leads = this.getLeadsById(new Set<Id> { leadId });
        return leads.isEmpty() ? null : leads[0];
    }
}