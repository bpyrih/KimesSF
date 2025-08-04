@isTest
private class WorkFileRelatedListControllerTest {
    public static Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ANSI').getRecordTypeId();
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opp', Project_Name__c = 'Test Project Name', AccountId = acc.Id, StageName = 'Draft', CloseDate = System.today(), RecordTypeId = recordTypeId);
        insert opp;

        // Create Work_File__c related to the Opportunity
        Work_File__c wf = new Work_File__c(
            Opportunity__c = opp.Id,
            Work_File_Name__c = 'Test Project Name',
            Status__c = 'Draft'
        );
        insert wf;

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test Project Name',
            PathOnClient = 'Test Project Name.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        // Retrieve auto-created ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // Create ContentDocumentLink between ContentDocument and Work_File__c
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = wf.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        // Add ContentDocumentLink relationship to Work_File__c (for upload logic)
        wf = [SELECT Id, (SELECT Id, ContentDocumentId FROM ContentDocumentLinks) FROM Work_File__c WHERE Id = :wf.Id];
    }

    @isTest
    static void testGetRelatedWorkFiles() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<WorkFileRelatedListController.FileInfo> files = WorkFileRelatedListController.getRelatedWorkFiles(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, files);
        System.assertEquals(1, files.size(), 'Expected 1 related file');
        System.assert(files[0].fileName.contains('Test Project Name'), 'File name should match');
    }

    @isTest
    static void testDownloadWorkFiles() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<WorkFileRelatedListController.FileInfo> files = WorkFileRelatedListController.getRelatedWorkFiles(opp.Id);

        Test.startTest();
        WorkFileRelatedListController.FileCollectionWrapper wrapper = WorkFileRelatedListController.downloadWorkFiles(opp.Id, files);
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assertEquals('Test Project Name', wrapper.opportunityName);
        System.assertEquals(1, wrapper.files.size());
        System.assert(wrapper.files[0].fileName.endsWith('.pdf'));
    }

    @isTest
    static void testUploadWorkFiles() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Simulate uploaded file wrapper
        WorkFileRelatedListController.WorkFileWrapper upload = new WorkFileRelatedListController.WorkFileWrapper();
        upload.fileName = 'Test Project Name.pdf';
        upload.fileContent = EncodingUtil.base64Encode(Blob.valueOf('Signed Content'));

        Test.startTest();
        Boolean result = WorkFileRelatedListController.uploadWorkFiles(opp.Id, new List<WorkFileRelatedListController.WorkFileWrapper>{upload});
        Test.stopTest();

        System.assertEquals(true, result, 'Upload should return true');
    }
}