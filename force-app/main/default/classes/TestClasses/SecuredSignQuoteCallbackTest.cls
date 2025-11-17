@IsTest
private class SecuredSignQuoteCallbackTest {

    private static Quote createQuoteOnly() {
        Account acc = new Account(Name = 'CB Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name           = 'CB Opportunity',
            AccountId      = acc.Id,
            StageName      = 'Prospecting',
            CloseDate      = Date.today().addDays(10),
            Project_Name__c = 'Test Project'
        );
        insert opp;

        Schema.DescribeFieldResult psDescribe =
            Quote.Payment_Schedule__c.getDescribe();
        List<Schema.PicklistEntry> psValues = psDescribe.getPicklistValues();
        System.assert(!psValues.isEmpty(), 'Payment_Schedule__c must have at least one picklist value');
        String paymentScheduleValue = psValues[0].getValue();

        Quote q = new Quote(
            Name                = 'Callback Quote',
            OpportunityId       = opp.Id,
            Status              = 'Draft',
            Payment_Schedule__c = paymentScheduleValue
        );
        insert q;

        return q;
    }

    @IsTest
    static void testCallback_FinalSigned_CreatesFileAndAcceptsQuote() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Quote q = createQuoteOnly();

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/SecuredSignQuoteCallback';
        req.httpMethod = 'POST';
        req.addParameter('quoteId', q.Id);
        req.addParameter('Status',  'Signed');
        req.addParameter('Doc',     'DOC-REF-123');

        RestResponse res = new RestResponse();
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        SecuredSignQuoteCallback.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Response must be 200');

        q = [
            SELECT Status
            FROM Quote
            WHERE Id = :q.Id
        ];
        System.assertEquals('Accepted', q.Status, 'Quote must be updated to Accepted');

        Integer cdlCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :q.Id
        ];
        System.assert(cdlCount > 0, 'There must be at least one ContentDocumentLink for Quote');
    }

    @IsTest
    static void testCallback_BlankQuoteId_NoWork() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/SecuredSignQuoteCallback';
        req.httpMethod = 'POST';

        RestResponse res = new RestResponse();
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        SecuredSignQuoteCallback.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Response must be 200 even if quoteId is blank');
    }

    @IsTest
    static void testCallback_NotFinal_NoFileNoStatusChange() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Quote q = createQuoteOnly();

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/SecuredSignQuoteCallback';
        req.httpMethod = 'POST';
        req.addParameter('quoteId', q.Id);
        req.addParameter('Status',  'Pending');
        req.addParameter('Doc',     'DOC-REF-123');

        RestResponse res = new RestResponse();
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        SecuredSignQuoteCallback.handlePost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Response must be 200');

        q = [
            SELECT Status
            FROM Quote
            WHERE Id = :q.Id
        ];
        System.assertNotEquals('Accepted', q.Status, 'Quote status must not be Accepted for non-final status');

        Integer cdlCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :q.Id
        ];
        System.assertEquals(0, cdlCount, 'No ContentDocumentLink must be created for non-final event');
    }
}
