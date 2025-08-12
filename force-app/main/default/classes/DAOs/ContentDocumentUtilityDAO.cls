public with sharing class ContentDocumentUtilityDAO {
    public List<ContentDocumentLink> getContentDocumentLinksByLinkedEntityIdsAndExtensions(List<Id> linkedEntityIds, List<String> extensions) {
        return [
            SELECT LinkedEntityId,
                    ContentDocumentId,
                    ContentDocument.Title,
                    ContentDocument.FileType,
                    ContentDocument.ContentSize,
                    ContentDocument.FileExtension,
                    ContentDocument.LatestPublishedVersionId,
                    ContentDocument.LatestPublishedVersion.Id,
                    ContentDocument.LatestPublishedVersion.VersionNumber,
                    ContentDocument.LatestPublishedVersion.LastModifiedDate
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :linkedEntityIds AND ContentDocument.FileExtension IN :extensions];
    }

    public List<ContentVersion> getContentVersionByIds(Set<Id> contentVersionIds) {
        return [SELECT Id, ContentDocumentId, VersionData, FileExtension, ContentDocument.Title FROM ContentVersion WHERE Id IN :contentVersionIds];
    }

    public List<ContentVersion> getContentVersionsByContentDocumentIds(Set<Id> contentDocumentIds) {
        return [SELECT Id, ContentDocumentId, VersionNumber, VersionDataURL, PathOnClient, Title, IsLatest, Description, ReasonForChange, CreatedDate, Is_Latest_Signed__c FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds ORDER BY CreatedDate DESC];
    }

}