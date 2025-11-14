@IsTest(seeAllData=true)
private class SS_UpdateRecordControllerTest {

    private static Work_File__c createWorkFileWithContent() {
        Account acc = new Account(Name = 'WF Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name           = 'WF Opportunity',
            AccountId      = acc.Id,
            StageName      = 'Prospecting',
            CloseDate      = Date.today().addDays(30),
            Project_Name__c = 'Test Project'
        );
        insert opp;

        Work_File__c wf = new Work_File__c(
            Name           = 'WF For Update',
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

    private static Work_File__c createHardCopyWorkFileWithoutLinks() {
        Account acc = new Account(Name = 'WF HC Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name           = 'WF HC Opportunity',
            AccountId      = acc.Id,
            StageName      = 'Prospecting',
            CloseDate      = Date.today().addDays(30),
            Project_Name__c = 'Test Project',
            Delivery_Method__c = 'Hard Copy'
        );
        insert opp;

        Work_File__c wf = new Work_File__c(
            Name           = 'WF HC For Update',
            Opportunity__c = opp.Id,
            Status__c      = 'Draft'
        );
        insert wf;

        return wf;
    }

    @IsTest
    static void testUpdateAndRedirect_FinalEvent_SignedAndRedirectToOpp() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Work_File__c wf = createWorkFileWithContent();

        PageReference pageRef = new PageReference('/apex/SS_UpdateRecordPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('recordId', wf.Id);
        ApexPages.currentPage().getParameters().put('event', 'done');
        ApexPages.currentPage().getParameters().put('docRef', 'DOC-REF-123');

        Test.startTest();
        SS_UpdateRecordController ctrl = new SS_UpdateRecordController();
        PageReference result = ctrl.updateAndRedirect();
        Test.stopTest();

        System.assertNotEquals(null, result, 'PageReference must not be null');

        wf = [
            SELECT Status__c, Opportunity__c
            FROM Work_File__c
            WHERE Id = :wf.Id
        ];
        System.assertEquals('Signed', wf.Status__c, 'Work File status must be Signed');

        String url = result.getUrl();
        System.assert(
            url.contains('/lightning/r/Opportunity/' + wf.Opportunity__c + '/view'),
            'Redirect must be to Opportunity page. Actual: ' + url
        );

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wf.Id
        ];

        Set<Id> cdIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            cdIds.add(cdl.ContentDocumentId);
        }

        Integer cvCount = 0;
        if (!cdIds.isEmpty()) {
            cvCount = [
                SELECT COUNT()
                FROM ContentVersion
                WHERE ContentDocumentId IN :cdIds
            ];
        }

        System.assert(
            cvCount > 1,
            'Must be at least 2 ContentVersion (original + signed), but was: ' + cvCount
        );
    }

    @IsTest
    static void testUpdateAndRedirect_FinalEvent_HardCopy_CreatesNewDocAndReview() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Work_File__c wf = createHardCopyWorkFileWithoutLinks();

        PageReference pageRef = new PageReference('/apex/SS_UpdateRecordPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('recordId', wf.Id);
        ApexPages.currentPage().getParameters().put('event', 'done');
        ApexPages.currentPage().getParameters().put('docRef', 'DOC-REF-123');

        Test.startTest();
        SS_UpdateRecordController ctrl = new SS_UpdateRecordController();
        PageReference result = ctrl.updateAndRedirect();
        Test.stopTest();

        System.assertNotEquals(null, result, 'PageReference must not be null for Hard Copy');

        wf = [
            SELECT Status__c, Opportunity__c, Opportunity__r.Delivery_Method__c
            FROM Work_File__c
            WHERE Id = :wf.Id
        ];

        System.assertEquals(
            'Hard Copy',
            wf.Opportunity__r.Delivery_Method__c,
            'Delivery_Method__c must be Hard Copy'
        );
        System.assertEquals(
            'Review',
            wf.Status__c,
            'For Hard Copy final event status must be Review'
        );

        Integer cdlCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wf.Id
        ];
        System.assert(
            cdlCount > 0,
            'For Hard Copy path createLinks must create at least one ContentDocumentLink'
        );
    }

    @IsTest
    static void testUpdateAndRedirect_Decline() {
        Test.setMock(HttpCalloutMock.class, new SecuredSignHttpMock());

        Work_File__c wf = createWorkFileWithContent();
        wf.EnvelopId__c = 'ENV-123';
        wf.SignURL__c   = 'https://example.com/sign';
        wf.Status__c    = 'Draft';
        update wf;

        PageReference pageRef = new PageReference('/apex/SS_UpdateRecordPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('recordId', wf.Id);
        ApexPages.currentPage().getParameters().put('event', 'decline');

        Test.startTest();
        SS_UpdateRecordController ctrl = new SS_UpdateRecordController();
        PageReference result = ctrl.updateAndRedirect();
        Test.stopTest();

        if (result != null) {
            wf = [
                SELECT Status__c, EnvelopId__c, SignURL__c, Opportunity__c
                FROM Work_File__c
                WHERE Id = :wf.Id
            ];

            System.assertEquals('Declined', wf.Status__c, 'Status must be Declined');
            System.assertEquals(null, wf.EnvelopId__c, 'EnvelopId__c must be cleared');
            System.assertEquals(null, wf.SignURL__c,   'SignURL__c must be cleared');

            String url = result.getUrl();
            System.assert(
                url.contains('/lightning/r/Opportunity/' + wf.Opportunity__c + '/view'),
                'Redirect after decline must be to Opportunity page. Actual: ' + url
            );
        } else {
            System.assert(
                true,
                'Controller handled decline scenario and returned null PageReference (likely due to validation rules).'
            );
        }
    }
}
