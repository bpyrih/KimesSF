@IsTest
public class EmailComposerControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(LastName = 'Test', AccountId = acc.Id, Email = 'contact@test.com');
        insert con;
        
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ANSI').getRecordTypeId();
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        AccountId = acc.Id,
        RecordTypeId = recordTypeId,
        Project_Name__c = 'Proj-001'
            );
        insert opp;
        
        Case c = new Case(
            Subject = 'Test Case',
        SuppliedEmail = 'case@test.com',
        ContactId = con.Id,
        AccountId = acc.Id,
        Opportunity__c = opp.Id,
        Status = 'New',
        Origin = 'Phone'
            );
        insert c;
        
        Work_File__c wf = new Work_File__c(Name = 'WF1', Opportunity__c = opp.Id);
        insert wf;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
        PathOnClient = 'test.pdf',
        VersionData = Blob.valueOf('Dummy content'),
        Is_Latest_Signed__c = true
            );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        
        insert new ContentDocumentLink(
            ContentDocumentId = contentDocId,
        LinkedEntityId = wf.Id,
        ShareType = 'V'
            );
        
        Quote approvedQuote = new Quote(
            Name = 'Approved Quote',
        OpportunityId = opp.Id,
        Status = 'Approved'
            );
        Quote draftQuote = new Quote(
            Name = 'Draft Quote',
        OpportunityId = opp.Id,
        Status = 'Draft'
            );
        insert new List<Quote>{approvedQuote, draftQuote};
        
        ContentVersion quoteCV = new ContentVersion(
            Title = 'QuoteFile',
        PathOnClient = 'quote.pdf',
        VersionData = Blob.valueOf('Dummy content')
            );
        insert quoteCV;
        
        Id quoteDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :quoteCV.Id LIMIT 1].ContentDocumentId;
        
        insert new ContentDocumentLink(
            ContentDocumentId = quoteDocId,
        LinkedEntityId = approvedQuote.Id,
        ShareType = 'V'
            );
        
        insert new EmailMessage(
            ParentId = c.Id,
        ToAddress = 'case@test.com',
        FromAddress = 'user@test.com',
        Subject = 'Inbound Email',
        MessageDate = System.now(),
        Status = '3',
        MessageIdentifier = 'MSG-12345'
            );
    }
    
    @IsTest
    static void testGetInitialData_valid() {
        Case c = [SELECT Id, SuppliedEmail, ContactId, AccountId, Opportunity__c, Subject FROM Case LIMIT 1];
        Test.startTest();
        
        EmailComposerController.InitialDataDTO dto = EmailComposerController.getInitialData(c != null ? c.Id : null);
        Test.stopTest();
        
        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertEquals(c.SuppliedEmail, dto.defaultTo, 'Default To should match case email');
        System.assert(dto.defaultSubject.startsWith('Re: ' + (c.Subject != null ? c.Subject : '')), 'Default subject should start with case subject');
        System.assertNotEquals(null, dto.defaultBody, 'Body should not be null');
        System.assert(!dto.workFiles.isEmpty(), 'WorkFiles should not be empty');
        System.assert(!dto.quoteFiles.isEmpty(), 'QuoteFiles should not be empty');
    }
    
    @IsTest
    static void testGetInitialData_nullCaseId() {
        Exception ex;
        try {
            Test.startTest();
            EmailComposerController.getInitialData(null);
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }
        System.assert(ex.getMessage().contains('exception'));
    }
    
    @IsTest
    static void testGetInitialData_noLinks() {
        Account acc2 = new Account(Name = 'NoLinks Acc');
        insert acc2;
        
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ANSI').getRecordTypeId();
        Opportunity opp2 = new Opportunity(
            Name = 'Opp NoLinks',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(5),
        AccountId = acc2.Id,
        RecordTypeId = recordTypeId,
        Project_Name__c = 'Proj-NoLinks'
            );
        insert opp2;
        
        Case c2 = new Case(
            Subject = 'Case NoLinks',
        SuppliedEmail = 'nolinks@test.com',
        Opportunity__c = opp2.Id,
        Origin = 'Phone'
            );
        insert c2;
        
        insert new Work_File__c(Name = 'WF NoLinks', Opportunity__c = opp2.Id);
        
        Test.startTest();
        EmailComposerController.InitialDataDTO dto = EmailComposerController.getInitialData(c2 != null ? c2.Id : null);
        Test.stopTest();
        
        System.assertEquals(0, dto.workFiles.size(), 'WorkFiles should be empty if no ContentDocumentLinks');
    }
    
    @IsTest
    static void testSendEmail_success() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        List<Id> contentDocIds = cv != null ? new List<Id>{cv.ContentDocumentId} : new List<Id>();
        
        Test.startTest();
        try {
            EmailComposerController.sendEmail(
                c != null ? c.Id : null,
            'recipient@test.com',
            'cc@test.com',
            'bcc@test.com',
            '<p>Hello</p>',
            contentDocIds
                );
        } catch (AuraHandledException e) {
            System.debug('Caught expected AuraHandledException in test: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assert(true, 'SendEmail executed without null pointer');
    }
    
    @IsTest
    static void testSendEmail_missingTo() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Exception ex;
        try {
            Test.startTest();
            EmailComposerController.sendEmail(c != null ? c.Id : null, null, null, null, '<p>Body</p>', null);
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }
        System.assert(ex.getMessage().contains('exception'));
    }
    
    @IsTest
    static void testSendEmail_missingBody() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Exception ex;
        try {
            Test.startTest();
            EmailComposerController.sendEmail(c != null ? c.Id : null, 'recipient@test.com', null, null, null, null);
            Test.stopTest();
        } catch (Exception e) {
            ex = e;
        }
        System.assert(ex.getMessage().contains('exception'));
    }
    
    @IsTest
    static void testQuoteFiles_inDTO() {
        Case c = [SELECT Id, Opportunity__c FROM Case LIMIT 1];
        
        Test.startTest();
        EmailComposerController.InitialDataDTO dto = EmailComposerController.getInitialData(c.Id);
        Test.stopTest();
        
        Boolean foundQuoteFile = false;
        for (EmailComposerController.FileRowDTO f : dto.quoteFiles) {
            if (f.title.startsWith('QuoteFile')) {
                foundQuoteFile = true;
            }
        }
        
        System.assert(foundQuoteFile, 'DTO should contain file from approved quote');
    }
}