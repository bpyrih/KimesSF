@isTest
public with sharing class WorkFileRelatedListControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity', 
            CloseDate = Date.today(), 
            StageName = 'Draft', 
            Project_Name__c = 'Test Project 1'
        );
        insert opp;

        // Create a custom Work_File__c record linked to the Opportunity
        Work_File__c wf = new Work_File__c(
            Name = 'Test Work File',
            Opportunity__c = opp.Id
        );
        insert wf;

        // Create a ContentVersion (file) and link it to the Work_File__c via ContentDocumentLink
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Sample content for testing'),
            IsMajorVersion = true
        );
        insert cv;

        // Retrieve the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Link the ContentDocument to the Work_File__c record
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = wf.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl2;

        ContentVersion cv1 = new ContentVersion(
            Title = 'TestFile2',
            PathOnClient = 'TestFile2.pdf',
            VersionData = Blob.valueOf('Sample content for testing'),
            IsMajorVersion = true
        );
        insert cv1;

        cv1 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id];

        // Link the ContentDocument to the Work_File__c record
        ContentDocumentLink cdl4 = new ContentDocumentLink(
            ContentDocumentId = cv1.ContentDocumentId,
            LinkedEntityId = opp.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl4;
    }

    @isTest
    static void testGetRelatedWorkFiles() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Project_Name__c = 'Test Project 1' LIMIT 1];

        Test.startTest();
        List<WorkFileRelatedListController.FileInfo> files = WorkFileRelatedListController.getRelatedWorkFiles(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, files, 'Files list should not be null');
        System.assertEquals(1, files.size(), 'There should be exactly one related file');
 
        WorkFileRelatedListController.FileInfo info = files[0];
        System.assertEquals('TestFile.PDF', info.fileName, 'File name should match');
        System.assert(info.contentDocumentId != null, 'ContentDocumentId should not be null');
        System.assert(info.fileType == 'pdf' || info.fileType == 'PDF', 'File type should be PDF');
        System.assert(info.versionNumber == 1, 'Version number should be 1');
        System.assertNotEquals(null, info.lastModified, 'Last modified date should be populated');
    }

    @isTest
    static void testNoWorkFiles() {
        Opportunity opp2 = new Opportunity(
            Name = 'No Files Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Project_Name__c = 'Test Project 2'
        );
        insert opp2;

        Test.startTest();
        List<WorkFileRelatedListController.FileInfo> files = WorkFileRelatedListController.getRelatedWorkFiles(opp2.Id);
        Test.stopTest();

        System.assertNotEquals(null, files, 'Files list should not be null');
        System.assertEquals(0, files.size(), 'There should be no related files');
    }


    @IsTest
    static void testSingleAndMultipleFiles() {
        // Fetch the case Id
        Opportunity cs = [SELECT Id, Name FROM Opportunity LIMIT 1];

        Test.startTest();
        WorkFileRelatedListController.CaseFileWrapper wrapper =
            WorkFileRelatedListController.downloadCaseFiles(cs.Id);
        Test.stopTest();

        // Assert CaseNumber matches
        System.assertEquals(cs.Name, wrapper.caseNumber,
            'Should return correct CaseNumber');

        // Expect 2 files
        System.assertEquals(2, wrapper.files.size(),
            'Should return both files');

        // Validate filenames and content
        Set<String> expectedNames = new Set<String>{'TestFile.pdf', 'TestFile2.pdf'};
        Set<String> actualNames = new Set<String>();
        Set<String> expectedContents = new Set<String>{ EncodingUtil.base64Encode(Blob.valueOf('Sample content for testing')),
                                                        EncodingUtil.base64Encode(Blob.valueOf('Sample content for testing')) };
        Set<String> actualContents = new Set<String>();

        for (WorkFileRelatedListController.FileWrapper fw : wrapper.files) {
            actualNames.add(fw.fileName);
            actualContents.add(fw.fileContent);
        }

        System.assertEquals(expectedNames, actualNames,
            'File names must match');
        System.assertEquals(expectedContents, actualContents,
            'File contents must match Base64 encoding');
    }
}