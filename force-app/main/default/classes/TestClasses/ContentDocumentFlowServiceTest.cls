@isTest
public with sharing class ContentDocumentFlowServiceTest {
    @isTest
    static void testSingleLinkPerClone() {
        // Prepare parent record
        Account parent = new Account(Name = 'Test Parent');
        insert parent;

        // Create a source ContentVersion to generate a ContentDocument
        ContentVersion source = new ContentVersion(
            Title = 'SampleDoc',
            PathOnClient = 'SampleDoc.txt',
            VersionData = Blob.valueOf('Test data'),
            IsMajorVersion = true
        );
        insert source;

        // Query to get the ContentDocument Id
        source = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :source.Id];
        Id sourceDocId = source.ContentDocumentId;

        // Prepare invocable request
        ContentDocumentFlowService.Request req = new ContentDocumentFlowService.Request();
        req.sourceContentDocumentId = sourceDocId;
        req.targetParentId = parent.Id;

        // Execute in test context
        Test.startTest();
        List<ContentDocumentFlowService.Response> resp = ContentDocumentFlowService.cloneDocs(
            new List<ContentDocumentFlowService.Request>{ req }
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(1, resp.size(), 'Should return exactly one response');
        Id clonedDocId = resp[0].newContentDocumentId;
        System.assertNotEquals(sourceDocId, clonedDocId, 'Clone should have a different document Id');

        // Verify only one ContentDocumentLink exists
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :clonedDocId
        ];
        System.assertEquals(2, links.size(), 'There should be 2 links for the cloned doc');
        ContentDocumentLink link = links[0];
        System.assertEquals(parent.Id, link.LinkedEntityId, 'Link should reference the parent record');
        System.assertEquals('V', link.ShareType);
        System.assertEquals('AllUsers', link.Visibility);
    }
}