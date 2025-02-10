@isTest
private class CaseDAOTest {
    @testSetup
    static void setupTestData() {
        // Create test Cases
        List<Case> testCases = new List<Case>{
            new Case(
                Subject = 'Test Case 1',
                Request_Type__c = 'Commercial Drafting',
                Client_Type__c = 'New Contractor',
                Delivery_Method__c = 'Digital',
                Flood_Zone__c = 'Zone 1',
                Project_Address__c = '123 Test St',
                Lot_Number__c = 'Lot 101',
                Property_Owner__c = 'Owner 1',
                Receive_Date__c = Date.today(),
                SuppliedEmail = 'test1@example.com',
                SuppliedPhone = '123-456-7890',
                SuppliedCompany = 'Test Company 1',
                SuppliedName = 'John Doe',
                Priority = 'High',
                Project_Description__c = 'Test Project 1 Description',
                Project_Name__c = 'Test Project 1'
            ),
            new Case(
                Subject = 'Test Case 2',
                Request_Type__c = 'Commercial Drafting',
                Client_Type__c = 'New Contractor',
                Delivery_Method__c = 'Digital',
                Flood_Zone__c = 'Zone 2',
                Project_Address__c = '456 Sample Rd',
                Lot_Number__c = 'Lot 202',
                Property_Owner__c = 'Owner 2',
                Receive_Date__c = Date.today().addDays(-1),
                SuppliedEmail = 'test2@example.com',
                SuppliedPhone = '987-654-3210',
                SuppliedCompany = 'Test Company 2',
                SuppliedName = 'Jane Smith',
                Priority = 'Medium',
                Project_Description__c = 'Test Project 2 Description',
                Project_Name__c = 'Test Project 2'
            )
        };
        insert testCases;
    }

    @isTest
    static void testGetCasesById() {
        List<Case> insertedCases = [SELECT Id FROM Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case c : insertedCases) {
            caseIds.add(c.Id);
        }

        CaseDAO caseDAO = new CaseDAO();
        List<Case> results = caseDAO.getCasesById(caseIds);

        Assert.areEqual(insertedCases.size(), results.size(), 'The number of cases returned should match the number of cases inserted.');
        for (Case result : results) {
            Assert.isNotNull(caseIds.contains(result.Id), 'The result should contain the expected case IDs.');
        }
    }

    @isTest
    static void testGetCaseById() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        CaseDAO caseDAO = new CaseDAO();
        Case result = caseDAO.getCaseById(testCase.Id);

        Assert.isNotNull(result, 'The result should not be null.');
        Assert.areEqual(testCase.Id, result.Id, 'The fetched case ID should match the requested case ID.');
    }

    @isTest
    static void testGetCasesByIdWithFields() {
        List<Case> insertedCases = [SELECT Id FROM Case];
        Set<Id> caseIds = new Set<Id>();
        for (Case c : insertedCases) {
            caseIds.add(c.Id);
        }

        Set<String> queryFields = new Set<String>{ 'Id', 'Subject', 'Priority' };

        CaseDAO caseDAO = new CaseDAO();
        List<Case> results = caseDAO.getCasesById(caseIds, queryFields);

        Assert.areEqual(2, results.size(), 'The result list should not be empty.');
        for (Case result : results) {
            Assert.isNotNull(caseIds.contains(result.Id), 'The result should contain the expected case IDs.');
            Assert.isNotNull(result.Subject, 'The subject field should not be null.');
            Assert.isNotNull(result.Priority, 'The priority field should not be null.');
        }
    }

    @isTest
    static void testGetCaseByIdWithFields() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Set<String> queryFields = new Set<String>{ 'Id', 'Subject', 'Priority' };

        CaseDAO caseDAO = new CaseDAO();
        Case result = caseDAO.getCaseById(testCase.Id, queryFields);

        Assert.isNotNull(result, 'The result should not be null.');
        Assert.areEqual(testCase.Id, result.Id, 'The fetched case ID should match the requested case ID.');
        Assert.isNotNull(result.Subject, 'The subject field should not be null.');
        Assert.isNotNull(result.Priority, 'The priority field should not be null.');
    }
}
