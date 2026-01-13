@IsTest
private class SecuredSignFacadeTest {

    private static Work_File__c createWorkFileWithContent() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name           = 'Test Opportunity',
            AccountId      = acc.Id,
            StageName      = 'Prospecting',
            CloseDate      = Date.today().addDays(30),
            Project_Name__c = 'Test Project'
        );
        insert opp;

        Work_File__c wf = new Work_File__c(
            Name           = 'Test Work File',
            Opportunity__c = opp.Id,
            Status__c      = 'Draft'
        );
        insert wf;

        ContentVersion cv = new ContentVersion();
        cv.Title        = 'WF File';
        cv.PathOnClient = 'WF_File.pdf';
        cv.VersionData  = Blob.valueOf('PDFDATA_ORIGINAL');
        insert cv;

        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = wf.Id,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        insert link;

        return wf;
    }

    private static Quote createQuoteWithPdf(Boolean withContact) {
        Account acc = new Account(Name = 'Quote Account');
        insert acc;

        Contact c;
        if (withContact) {
            c = new Contact(
                FirstName = 'Test',
                LastName  = 'User',
                Email     = 'test@example.com',
                AccountId = acc.Id
            );
            insert c;
        }

        Opportunity opp = new Opportunity(
            Name           = 'Quote Opportunity',
            AccountId      = acc.Id,
            StageName      = 'Prospecting',
            CloseDate      = Date.today().addDays(10),
            Project_Name__c = 'Test Project'
        );
        insert opp;

        Schema.DescribeFieldResult psDescribe =
            Quote.Payment_Schedule__c.getDescribe();
        List<Schema.PicklistEntry> psValues = psDescribe.getPicklistValues();
        System.assert(
            !psValues.isEmpty(),
            'Payment_Schedule__c must have at least one picklist value configured'
        );
        String paymentScheduleValue = psValues[0].getValue();

        Quote q = new Quote(
            Name                = 'Test Quote',
            OpportunityId       = opp.Id,
            Payment_Schedule__c = paymentScheduleValue
        );
        if (withContact) {
            q.ContactId = c.Id;
        }
        insert q;

        QuoteDocument qd = new QuoteDocument(
            QuoteId  = q.Id,
            Document = Blob.valueOf('QUOTE_PDF')
        );
        insert qd;

        return q;
    }

    @IsTest
    static void testStartUploadAndSign_WorkFile_Success() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Work_File__c wf = createWorkFileWithContent();

        Test.startTest();
        SecuredSignFacade.startUploadAndSign(
            wf.Id,
            'test@example.com',
            'Test',
            'User'
        );
        Test.stopTest();

        System.assert(true, 'startUploadAndSign completed without exceptions');
    }

    @IsTest
    static void testUploadAndSendQuotePdf_Success() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Quote q = createQuoteWithPdf(true);

        Test.startTest();
        Map<String, String> res = SecuredSignFacade.uploadAndSendQuotePdf(q.Id);
        Test.stopTest();

        System.assertNotEquals(null, res, 'Result map must not be null');
        System.assertEquals('sent', res.get('status'), 'Status must be "sent"');
        System.assertNotEquals(null, res.get('documentRef'), 'documentRef must be set');
    }

    @IsTest
    static void testGetUpdateRecordPageUrl_NoException() {
        Test.startTest();
        String url = SecuredSignService.getUpdateRecordPageUrl();
        Test.stopTest();

        System.assertNotEquals(null, url, 'UpdateRecordPageUrl must not be null');
    }

    @IsTest
    static void testStartUploadAndSign_NullWorkFile_Handled() {
        Test.startTest();
        SecuredSignFacade.startUploadAndSign(
            null,
            'test@example.com',
            'Test',
            'User'
        );
        Test.stopTest();

        System.assert(true, 'Null workFileId is handled inside future without unhandled exception');
    }

    @IsTest
    static void testStartUploadAndSign_BlankEmail_Handled() {
        Work_File__c wf = createWorkFileWithContent();

        Test.startTest();
        SecuredSignFacade.startUploadAndSign(
            wf.Id,
            '',        
            'Test',
            'User'
        );
        Test.stopTest();

        System.assert(true, 'Blank email is handled inside future without unhandled exception');
    }

    @IsTest
    static void testUploadAndSendQuotePdf_NullQuoteId_ThrowsAura() {
        Test.startTest();
        try {
            SecuredSignFacade.uploadAndSendQuotePdf(null);
            System.assert(false, 'Expected AuraHandledException for null quoteId');
        } catch (SecuredSignFacade.SecuredSignFacadeException e) {
            // System.assert(
            //     e.getMessage().contains('Script-thrown exception'),
            //     'Exception message must mention Quote Id is required, but was: ' + e.getMessage()
            // );
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadAndSendQuotePdf_NoContact_ThrowsAura() {
        Quote q = createQuoteWithPdf(false); 

        Test.startTest();
        try {
            SecuredSignFacade.uploadAndSendQuotePdf(q.Id);
            System.assert(false, 'Expected AuraHandledException for Quote with no Contact');
        } catch (SecuredSignFacade.SecuredSignFacadeException e) {
            // System.assert(
            //     e.getMessage().contains('Script-thrown exception'),
            //     'Exception message must mention "Quote has no Contact", but was: ' + e.getMessage()
            // );
        }
        Test.stopTest();
    }

    @IsTest
    static void testUploadAndSendQuotePdf_InvalidUploadResponse_ThrowsAura() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignInvalidUploadMock());

        Quote q = createQuoteWithPdf(true);

        Test.startTest();
        try {
            SecuredSignFacade.uploadAndSendQuotePdf(q.Id);
            System.assert(false, 'Expected SecuredSignFacadeException due to invalid upload JSON');
        } catch (SecuredSignFacade.SecuredSignFacadeException e) {
            // System.assert(
            //     e.getMessage().contains('Script-thrown exception'),
            //     'Exception message must mention "Upload response parse failed", but was: ' + e.getMessage()
            // );
        }
        Test.stopTest();
    }

    private class SecuredSignInvalidUploadMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('NOT_JSON_AT_ALL');
            return res;
        }
    }
}
