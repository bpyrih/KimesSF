public with sharing class WorkFileRelatedListController {
    /** Simple wrapper to send file data to the LWC */
    public class FileInfo {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileType;
        @AuraEnabled public Integer fileSize;
        @AuraEnabled public Integer versionNumber;
        @AuraEnabled public DateTime lastModified;
        public FileInfo(ContentDocument doc, ContentVersion ver) {
            this.contentDocumentId = doc.Id;
            this.fileName          = doc.Title + (doc.FileType != null ? '.'+doc.FileType : '');
            this.fileType          = doc.FileType;
            this.fileSize          = Integer.valueOf(doc.ContentSize);
            this.versionNumber     = Integer.valueOf(ver.VersionNumber);
            this.lastModified      = ver.LastModifiedDate;
        }
    }
    
    /** 
     * Returns files attached to all Work_File__c records   
     * related to the given Opportunity.
     */
    @AuraEnabled(cacheable=true)
    public static List<FileInfo> getRelatedWorkFiles(Id opportunityId) {
        // 1) get all Work_File__c records for this Opportunity
        List<Work_File__c> wfList = [
            SELECT Id 
            FROM Work_File__c 
            WHERE Opportunity__c = :opportunityId
        ];
        if (wfList.isEmpty()) {
            return new List<FileInfo>();
        }
        Set<Id> wfIds = new Set<Id>();
        for (Work_File__c wf : wfList) wfIds.add(wf.Id);
        
        // 2) find ContentDocumentLink records for those work files
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                   ContentDocument.Title,
                   ContentDocument.FileType,
                   ContentDocument.ContentSize,
                   ContentDocument.LatestPublishedVersion.Id,
                   ContentDocument.LatestPublishedVersion.VersionNumber,
                   ContentDocument.LatestPublishedVersion.LastModifiedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :wfIds
        ];
        
        // 3) build FileInfo wrappers
        List<FileInfo> results = new List<FileInfo>();
        for (ContentDocumentLink l : links) {
            // LatestPublishedVersion is automatically populated via the sub-query
            ContentDocument doc = l.ContentDocument;
            ContentVersion ver = l.ContentDocument.LatestPublishedVersion;
            results.add(new FileInfo(doc, ver));
        }
        return results;
    }


    @AuraEnabled
   public static CaseFileWrapper downloadCaseFiles(Id caseId) {
      List<FileWrapper> files = new List<FileWrapper>();
      Opportunity cs = [SELECT Name FROM Opportunity WHERE Id = :caseId LIMIT 1];

      List<ContentDocumentLink> cdlList = [SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId = :caseId];
      Set<Id> versionIds = new Set<Id>();
      for (ContentDocumentLink link : cdlList) versionIds.add(link.ContentDocument.LatestPublishedVersionId);
      Map<Id, ContentVersion> cvs = new Map<Id, ContentVersion>(
         [SELECT Id, VersionData, FileExtension 
          FROM ContentVersion WHERE Id IN :versionIds]
      );
      for (ContentDocumentLink link : cdlList) {
        ContentVersion cv = cvs.get(link.ContentDocument.LatestPublishedVersionId);
        if (cv != null) {
            String b64 = EncodingUtil.base64Encode(cv.VersionData);
            String name = link.ContentDocument.Title + '.' + cv.FileExtension;
            files.add(new FileWrapper(name, b64));
        }
      }
      return new CaseFileWrapper(cs.Name, files);
   }

   public class FileWrapper {
      @AuraEnabled public String fileName;
      @AuraEnabled public String fileContent;
      public FileWrapper(String fn, String fc) { fileName=fn; fileContent=fc; }
   }

   public class CaseFileWrapper {
      @AuraEnabled public String caseNumber;
      @AuraEnabled public List<FileWrapper> files;
      public CaseFileWrapper(String cn, List<FileWrapper> fs) { caseNumber=cn; files=fs; }
   }
}