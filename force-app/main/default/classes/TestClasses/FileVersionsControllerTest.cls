@isTest
public with sharing class FileVersionsControllerTest {
    @isTest
    static void getFileVersionsTest() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Project_Name__c = 'Test Project'
        );
        insert opp;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test_File.pdf',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert testContentVersion;

        testContentVersion = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :testContentVersion.Id
        ];

        ContentDocument testContentDocument = [
            SELECT Id FROM ContentDocument WHERE Id = :testContentVersion.ContentDocumentId
        ];

        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = testContentDocument.Id,
            ShareType = 'V'
        );
        insert testContentDocumentLink;

        FileVersionsController.getFileVersions(opp.Id);
    }
}