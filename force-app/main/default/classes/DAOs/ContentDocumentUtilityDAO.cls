public with sharing class ContentDocumentUtilityDAO {
    public List<ContentDocumentLink> getContentDocumentLinksByLinkedEntityIdsAndExtensions(List<Id> linkedEntityIds, List<String> extensions) {
        return [SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.FileType, ContentDocument.FileExtension, ContentDocument.Title
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :linkedEntityIds AND ContentDocument.FileExtension IN :extensions];
    }

    public List<ContentVersion> getContentVersionByIds(Set<Id> contentVersionIds) {
        return [SELECT Id, VersionData FROM ContentVersion WHERE Id IN :contentVersionIds];
    }

}