@isTest
private class DocumentSignConfigControllerTest {

    @isTest
    static void testGetTemplateByName() {
        // Create test data
        Document_Sign_Config__c config = new Document_Sign_Config__c(
            Document_Sign_Template__c = 'ANSI Engineering',
            Config_Fields__c = 'Field1,Field2'
        );
        insert config;

        // Add child element (optional, to exercise subquery)
        Document_Sign_Element__c element = new Document_Sign_Element__c(
            Document_Sign_Config__c = config.Id,
            Page_Number__c = 1,
            xPosition__c = 100,
            yPosition__c = 200,
            width__c = 150,
            value__c = 'TestValue',
            Element_Type__c = 'Text'
        );
        insert element;

        // Clear static variables to simulate fresh context
        Test.startTest();
        Document_Sign_Config__c result = DocumentSignConfigController.getTempateByName('ANSI Engineering');
        Test.stopTest();

        // Assert result
        System.assertNotEquals(null, result, 'Expected to retrieve the config');
        System.assertEquals('ANSI Engineering', result.Document_Sign_Template__c, 'Template name should match');
    }
}