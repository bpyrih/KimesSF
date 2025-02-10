@isTest
public class ConversionControllerTest {
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
            SuppliedEmail = 'test1001ConvertCont@example.com',
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
    static void convertCaseToLeadTest() {
        Case testCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'test1001ConvertCont@example.com' LIMIT 1];

        Id convertedLeadId = ConversionController.convertCaseToLead(testCase.Id);
        
        System.assertNotEquals(null, convertedLeadId, 'Lead should be created');
    }
    @isTest
    static void convertCaseToOpportunityTest() {
        Case testCase = [SELECT Id FROM Case WHERE SuppliedEmail = 'test1001ConvertCont@example.com' LIMIT 1];

        Id convertedOpportunityId = ConversionController.convertCaseToOpportunity(testCase.Id);
        
        System.assertNotEquals(null, convertedOpportunityId, 'Opportunity should be created');
    }
    @isTest
    static void convertCaseToLeadTestError() {
        Case testCase = [SELECT Id, SuppliedName FROM Case WHERE SuppliedEmail = 'test1001ConvertCont@example.com' LIMIT 1];
        testCase.SuppliedName = null;
        update testCase;
        Id convertedLeadId;
        try {
            convertedLeadId = ConversionController.convertCaseToLead(testCase.Id);
        } catch(Exception ex) {

        }        
        
        System.assertEquals(null, convertedLeadId, 'Lead should not be created');
    }
    @isTest
    static void convertCaseToOpportunityTestError() {
        Case testCase = [SELECT Id, SuppliedName FROM Case WHERE SuppliedEmail = 'test1001ConvertCont@example.com' LIMIT 1];
        testCase.SuppliedName = null;
        update testCase;
        Id convertedOpportunityId;
        try {
            convertedOpportunityId = ConversionController.convertCaseToLead(testCase.Id);
        } catch(Exception ex) {

        }        
        
        System.assertEquals(null, convertedOpportunityId, 'Lead should not be created');
    }
}