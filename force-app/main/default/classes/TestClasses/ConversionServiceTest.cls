@isTest
private class ConversionServiceTest {
    @testSetup
    static void setupTestData() {
        // Create test Case
        Case testCase =  new Case(
            Subject = 'Test Case 1',
            Request_Type__c = 'Commercial Drafting',
            Client_Type__c = 'New Contractor',
            Delivery_Method__c = 'Digital',
            Flood_Zone__c = 'Zone 1',
            Project_Address__c = '123 Test St',
            Lot_Number__c = 'Lot 101',
            Property_Owner__c = 'Owner 1',
            Receive_Date__c = Date.today(),
            SuppliedEmail = 'test1001Convert@example.com',
            SuppliedPhone = '123-456-7890',
            SuppliedCompany = 'Test Company 1',
            SuppliedName = 'John Doe',
            Priority = 'High',
            Project_Description__c = 'Test Project 1 Description',
            Project_Name__c = 'Test Project 1'
        );
        insert testCase;
    
    }

    @isTest
    static void testConvertCaseToLead() {
        Case testCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'test1001Convert@example.com' LIMIT 1];
        // ConversionService.convMappingMetadataService = getTestConversionMappingsMetadataService();
        ConversionService service = new ConversionService();
        Lead convertedLead = service.convertCaseToLead(testCase.Id, true);
        
        System.assertNotEquals(null, convertedLead, 'Lead should be created');
        System.assertEquals('John Doe Company', convertedLead.Company, 'Lead should have correct data');
    }
    
    @isTest
    static void testConvertLeadToOpportunity() {
        Lead testLead = new Lead(FirstName = 'John', LastName = 'Doe', Company = 'Test Co', Email = 'test@example.com', Status = 'Open', Project_Name__c = 'Test Project 1');
        insert testLead;
        
        ConversionService service = new ConversionService();
        
        Id opportunityId = service.convertLeadToOpportunity(testLead.Id);
        
        System.assertNotEquals(null, opportunityId, 'Opportunity should be created');
    }
    
    @isTest
    static void testMarkCaseAsConverted() {
        Case testCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'test1001Convert@example.com' LIMIT 1];
        Lead testLead = new Lead(FirstName = 'John', LastName = 'Doe', Company = 'Test Co', Email = 'test@example.com', Status = 'Open', Project_Name__c = 'Test Project 1');
        insert testLead;
        
        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today(), StageName = 'Draft', Project_Name__c = 'Test Project 1');
        insert testOpp;
        
        ConversionService service = new ConversionService();
        service.markCaseAsConverted(testCase.Id, testLead.Id, testOpp.Id);
        
        Case updatedCase = [SELECT Converted_Lead__c, Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testLead.Id, updatedCase.Converted_Lead__c, 'Case should be linked to converted Lead');
        System.assertEquals('Closed', updatedCase.Status, 'Case status should be updated');
    }
}