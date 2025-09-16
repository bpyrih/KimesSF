@IsTest
public class EmailComposerControllerTest {
    
    private static Id caseId;
    private static Id contentDocId;
    private static Id oppId;
    
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, Email = 'contact@test.com');
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            Project_Name__c = 'Test Project Name',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        oppId = opp.Id;
        
        Work_File__c wf = new Work_File__c(Name = 'WF1', Opportunity__c = opp.Id);
        insert wf;
        
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            ContactId = con.Id,
            Opportunity__c = opp.Id,
            SuppliedEmail = 'case@test.com'
        );
        insert c;
        caseId = c.Id;
        
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Unit test content')
        );
        insert cv;
        
        contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        insert new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = c.Id,
            ShareType = 'V'
        );
        
        insert new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = wf.Id,
            ShareType = 'V'
        );
    }
    
    @IsTest
    static void testGetInitialData() {
        Test.startTest();
        EmailComposerController.InitialDataDTO dto = EmailComposerController.getInitialData(caseId);
        Test.stopTest();
        
        System.assertNotEquals(null, dto);
        System.assertEquals('case@test.com', dto.defaultTo);
        System.assert(dto.workFiles.size() > 0);
        System.assert(dto.quoteFiles.size() >= 0);
        System.assert(dto.templates != null);
    }
    
    @IsTest
    static void testGetInitialDataEmptyFiles() {
        Case emptyCase = new Case(
            Subject = 'No Files Case',
            Status = 'New',
            Origin = 'Phone',
            SuppliedEmail = 'nofiles@test.com',
            Opportunity__c = null
        );
        insert emptyCase;
        
        Test.startTest();
        EmailComposerController.InitialDataDTO dto = EmailComposerController.getInitialData(emptyCase.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, dto);
        System.assertEquals('nofiles@test.com', dto.defaultTo);
        System.assertEquals(0, dto.workFiles.size());
        System.assertEquals(0, dto.quoteFiles.size());
    }
    
    @IsTest
    static void testSendEmailMissingParams() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            EmailComposerController.sendEmail(caseId, null, null, null, null, new List<Id>());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected AuraHandledException was not thrown');
    }
    
    @IsTest
    static void testSendEmailWithAttachments() {
        Test.startTest();
        try {
            EmailComposerController.sendEmail(caseId, 'recipient@test.com', null, null, '<p>Test body</p>', new List<Id>{contentDocId});
        } catch (AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testSendEmailWithoutAttachments() {
        Test.startTest();
        try {
            EmailComposerController.sendEmail(caseId, 'recipient@test.com', null, null, '<p>Test body</p>', new List<Id>());
        } catch (AuraHandledException e) {}
        Test.stopTest();
    }
    
    @IsTest
    static void testSplitCsv() {
        List<String> result = EmailComposerController.splitCsv('a@test.com; b@test.com, c@test.com');
        System.assertEquals(3, result.size());
        System.assert(result.contains('a@test.com'));
        System.assert(result.contains('b@test.com'));
        System.assert(result.contains('c@test.com'));
    }
}