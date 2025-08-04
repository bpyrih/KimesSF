public with sharing class WorkFileRelatedListController {
    private static ContentDocumentUtilityDAO contentDocumentUtilityDAO = new ContentDocumentUtilityDAO();
    private static WorkFileDAO workFileDAO = new WorkFileDAO();

    @AuraEnabled(cacheable=true)
    public static List<FileInfo> getRelatedWorkFiles(Id opportunityId) {
        Map<Id, Work_File__c> wfMap = new Map<Id, Work_File__c>(workFileDAO.getWorkFilesByOpportunityIds(new Set<Id> {opportunityId}));
        if (wfMap.isEmpty()) {
            return new List<FileInfo>();
        }
        
        List<ContentDocumentLink> links = contentDocumentUtilityDAO.getContentDocumentLinksByLinkedEntityIdsAndExtensions(new List<Id>(wfMap.keySet()), new List<String>{'pdf'});
        
        List<FileInfo> results = new List<FileInfo>();
        for (ContentDocumentLink link : links) {
            results.add(new FileInfo(link, wfMap.get(link.LinkedEntityId)));
        }
        return results;
    }

    @AuraEnabled
    public static FileCollectionWrapper downloadWorkFiles(Id opportunityId, List<FileInfo> workFileInfos) {
        List<WorkFileWrapper> wfWrapperList = new List<WorkFileWrapper>();
        Map<Id, FileInfo> contentVersionIdToFileInfoMap = new Map<Id, FileInfo>();
        for (FileInfo fi : workFileInfos) {
            contentVersionIdToFileInfoMap.put(fi.versionId, fi);
        }
        List<ContentVersion> contentVersions = contentDocumentUtilityDAO.getContentVersionByIds(contentVersionIdToFileInfoMap.keySet());

        for (ContentVersion contentVersion : contentVersions) {
            String b64 = EncodingUtil.base64Encode(contentVersion.VersionData);
            String name = contentVersion.ContentDocument.Title + '.' + contentVersion.FileExtension;
            wfWrapperList.add(new WorkFileWrapper(name, b64));
        }

        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :opportunityId][0];

        return new FileCollectionWrapper(opp.Name, wfWrapperList);
    }

    @AuraEnabled
    public static Boolean uploadWorkFiles(Id opportunityId, List<WorkFileWrapper> uploadFiles) {
        Map<Id, Work_File__c> wfMap = new Map<Id, Work_File__c>(workFileDAO.getWorkFilesByOpportunityIds(new Set<Id> {opportunityId}));
        if (wfMap.isEmpty()) {
            return false;
        }

        List<ContentDocumentLink> links = contentDocumentUtilityDAO.getContentDocumentLinksByLinkedEntityIdsAndExtensions(new List<Id>(wfMap.keySet()), new List<String>{'pdf'});

        List<ContentVersion> cvs = new List<ContentVersion>();

        List<Work_File__c> workFilesForSing = new List<Work_File__c>();

        for (Integer i = 0; i < uploadFiles.size(); i++) {
            WorkFileWrapper f = uploadFiles[i];

            String docId;
            for (Work_File__c wf : wfMap.values()) {
                if (f.fileName.contains(wf.Work_File_Name__c)) {
                    if (!wf.ContentDocumentLinks.isEmpty()) {
                        docId = wf.ContentDocumentLinks[0].ContentDocumentId;
                    }
                }
            }

            if (docId == null) {
                continue;
            }

            Id workFileId;
            for (ContentDocumentLink cdLink : links) {
                if (docId == cdLink.ContentDocumentId) {
                    workFileId = cdLink.LinkedEntityId;
                    break;
                }
            }

            if (workFileId == null) {
                continue;
            }

            workFilesForSing.add(new Work_File__c(Id = workFileId, Status__c = 'Signed'));

            ContentVersion cv = new ContentVersion();
            String title = f.fileName;
            cv.Title = title.replace('.pdf', '');
            cv.PathOnClient = title;
            cv.Description = 'Signed Version';
            cv.VersionData = EncodingUtil.base64Decode(f.fileContent);
            cv.ContentDocumentId = docId;

            cvs.add(cv);
        }

        insert cvs;

        update workFilesForSing;

        return true;
    }

    public class FileCollectionWrapper {
        @AuraEnabled public String opportunityName;
        @AuraEnabled public List<WorkFileWrapper> files;
        public FileCollectionWrapper(String oppName, List<WorkFileWrapper> fis) { opportunityName = oppName; files = fis; }
    }

    public class WorkFileWrapper {
        @AuraEnabled public String fileName {get; set;}
        @AuraEnabled public String fileContent {get; set;}
        public WorkFileWrapper(String fn, String fc) { fileName=fn; fileContent=fc; }
        public WorkFileWrapper() {}
    }

    public class FileInfo {
        @AuraEnabled public Id contentDocumentId {get; set;}
        @AuraEnabled public Id versionId {get; set;}
        @AuraEnabled public String fileName {get; set;}
        @AuraEnabled public String fileType {get; set;}
        @AuraEnabled public Integer fileSize {get; set;}
        @AuraEnabled public Integer versionNumber {get; set;}
        @AuraEnabled public DateTime lastModified {get; set;}
        @AuraEnabled public Id workFileId {get; set;}
        @AuraEnabled public String workFileStatus {get; set;}
        public FileInfo(ContentDocumentLink link, Work_File__c workFile) {
            this.contentDocumentId = link.ContentDocumentId;
            this.versionId         = link.ContentDocument.LatestPublishedVersionId;
            this.fileName          = link.ContentDocument.Title + (link.ContentDocument.FileExtension != null ? '.' + link.ContentDocument.FileExtension : '');
            this.fileType          = link.ContentDocument.FileType;
            this.fileSize          = Integer.valueOf(link.ContentDocument.ContentSize);
            this.versionNumber     = Integer.valueOf(link.ContentDocument.LatestPublishedVersion.VersionNumber);
            this.lastModified      = link.ContentDocument.LatestPublishedVersion.LastModifiedDate;
            this.workFileId        = link.LinkedEntityId;
            this.workFileStatus    = workFile.Status__c;
        }
        public FileInfo() {

        }
    }
}