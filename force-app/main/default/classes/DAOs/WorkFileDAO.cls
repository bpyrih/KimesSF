public with sharing class WorkFileDAO {
    public List<Work_File__c> getWorkFilesByOpportunityIds(Set<Id> opportunityIds) {
        return [
            SELECT Id, Status__c, Document_Sign_Template__c, Work_File_Name__c,
            (SELECT ContentDocumentId FROM ContentDocumentLinks LIMIT 1)
            FROM Work_File__c
            WHERE Opportunity__c IN :opportunityIds
        ];
    }
    
    public List<Work_File__c> getWorkFilesByIds(Set<Id> ids) {
        return [
            SELECT Id, Status__c, Document_Sign_Template__c, Work_File_Name__c
            FROM Work_File__c
            WHERE Id IN :ids
        ];
    }
    
    public Work_File__c getWorkFile(Id workFileId, Set<String> configFields) {
        String queryString = 'SELECT {0} FROM Work_File__c WHERE Id = :workFileId';
        queryString = String.format(queryString, new List<String> {String.join(configFields, ',')});
        Work_File__c workFileConfig = Database.query(queryString);
        return workFileConfig;
    }
    
    public static ContentVersion getLatestVersion(Id workFileId) {
        if (workFileId == null) {
            throw new AuraHandledException('WorkFile Id is null');
        }
        
        List<ContentDocumentLink> links = [
        SELECT ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :workFileId
    ];
        if (links.isEmpty()) {
            return null;
        }
        
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            docIds.add(cdl.ContentDocumentId);
        }
        
        List<ContentVersion> versions = [
        SELECT Id, Title, FileExtension, ContentDocumentId, VersionNumber,
               ContentSize, FileType, LastModifiedDate, VersionData, Is_Latest_Signed__c
        FROM ContentVersion
        WHERE ContentDocumentId IN :docIds
          AND  Is_Latest_Signed__c=false
        ORDER BY LastModifiedDate DESC
        LIMIT 1
    ];
        
        return versions.isEmpty() ? null : versions[0];
    }
}