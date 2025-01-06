@isTest
public class UpdateRecordControllerTest {
    public static Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ANSI').getRecordTypeId();
    @isTest
    static void testUpdateAndRedirect() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opp', Project_Name__c = 'Test Project Name', AccountId = acc.Id, StageName = 'Draft', CloseDate = System.today(), RecordTypeId = recordTypeId);
        insert opp;

        Work_File__c testRecord = new Work_File__c(Name = 'Test Work File', Status__c = 'Draft', Opportunity__c = opp.Id);
        insert testRecord;

        Test.startTest();
        PageReference pageRef = Page.UpdateRecordPage; // Replace with your Visualforce page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('recordId', testRecord.Id);

        UpdateRecordController controller = new UpdateRecordController();
        PageReference result = controller.updateAndRedirect();
        Test.stopTest();

        testRecord = [SELECT Name, Status__c FROM Work_File__c WHERE Id = :testRecord.Id];
        System.assertEquals('Signed', testRecord.Status__c, 'Record name should be updated.');
        System.assertNotEquals(null, result, 'Resulting page reference should not be null.');
        System.assertEquals('/' + testRecord.Id, result.getUrl(), 'Redirect URL should point to the updated record.');
    }
}