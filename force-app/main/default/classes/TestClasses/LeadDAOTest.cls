@isTest
private class LeadDAOTest {
    @testSetup
    static void setupTestData() {
        List<Lead> testLeads = new List<Lead>{
            new Lead(FirstName = 'Test', LastName = 'Lead1', Company = 'Test Company 1', Email = 'test1@example.com', Request_Type__c = 'ANSI + Standards', Project_Name__c = 'Test'),
            new Lead(FirstName = 'Test', LastName = 'Lead2', Company = 'Test Company 2', Email = 'test2@example.com', Request_Type__c = 'ANSI + Standards', Project_Name__c = 'Test')
        };
        insert testLeads;
    }

    @isTest
    static void testGetLeadsById() {
        // Fetch test data
        List<Lead> leads = [SELECT Id FROM Lead];
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        // Test the getLeadsById method
        LeadDAO leadDAO = new LeadDAO();
        List<Lead> results = leadDAO.getLeadsById(leadIds);

        Assert.areEqual(leads.size(), results.size(), 'The number of leads fetched should match the number of leads inserted.');
        for (Lead result : results) {
            Assert.isNotNull(leadIds.contains(result.Id), 'The result should contain the expected lead IDs.');
        }
    }

    @isTest
    static void testGetLeadById() {
        // Fetch a single lead ID
        Lead testLead = [SELECT Id, Request_Type__c FROM Lead LIMIT 1];
        
        // Test the getLeadById method
        LeadDAO leadDAO = new LeadDAO();
        Lead result = leadDAO.getLeadById(testLead.Id);

        Assert.areEqual(testLead.Id, result.Id, 'The fetched lead ID should match the requested lead ID.');
        Assert.areEqual(testLead.Request_Type__c, result.Request_Type__c, 'The fetched lead should have the correct Request_Type__c.');
    }
}