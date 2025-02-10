@isTest
private class ContentDocumentUtilityDAOTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

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
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = testContentDocument.Id,
            ShareType = 'V'
        );
        insert testContentDocumentLink;
    }

    @isTest
    static void testGetContentDocumentLinksByLinkedEntityIdsAndExtensions() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<String> extensions = new List<String>{ 'pdf' };

        ContentDocumentUtilityDAO dao = new ContentDocumentUtilityDAO();
        List<ContentDocumentLink> results = dao.getContentDocumentLinksByLinkedEntityIdsAndExtensions(
            new List<Id>{ testAccount.Id },
            extensions
        );

        Assert.areNotEqual(0, results.size(), 'Results should not be empty.');
        for (ContentDocumentLink link : results) {
            Assert.areEqual('pdf', link.ContentDocument.FileExtension, 'The file extension should match the expected value.');
        }
    }

    @isTest
    static void testGetContentVersionByIds() {
        ContentVersion testContentVersion = [SELECT Id FROM ContentVersion LIMIT 1];

        ContentDocumentUtilityDAO dao = new ContentDocumentUtilityDAO();
        List<ContentVersion> results = dao.getContentVersionByIds(new Set<Id>{ testContentVersion.Id });

        Assert.areEqual(1, results.size(), 'There should be exactly one result.');
        Assert.areEqual(testContentVersion.Id, results[0].Id, 'The ContentVersion ID should match the requested ID.');
    }
}