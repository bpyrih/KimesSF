public with sharing class FileVersionsController {
    private static ContentDocumentUtilityDAO contentDocumentUtilityDAO = new ContentDocumentUtilityDAO();
    public class ComboboxOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String fileName;
        @AuraEnabled public Boolean isLatest;
        @AuraEnabled public String versionURL;
        @AuraEnabled public String description;
        @AuraEnabled public String reason;
        @AuraEnabled public DateTime createdDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<ComboboxOption> getFileVersions(String recordId) {
        List<ComboboxOption> options = new List<ComboboxOption>();
        String contentDocId;

        // Step 1: Get ContentDocumentId from ContentDocumentLink
        try {
            List<ContentDocumentLink> cdLinks = contentDocumentUtilityDAO.getContentDocumentLinksByLinkedEntityIdsAndExtensions(new List<String>{recordId}, new List<String> {'pdf'});
            if (!cdLinks.isEmpty()){
                contentDocId = cdLinks[0].ContentDocumentId;
            }
        } catch (QueryException e) {
            // Handle case where no file is linked to the record
            System.debug('No ContentDocumentLink found for recordId: ' + recordId + ' Error: ' + e.getMessage());
            return options; // Return empty list
        }

        if (contentDocId!= null) {
            // Step 2: Get all ContentVersion records for that ContentDocumentId
            List<ContentVersion> versions = contentDocumentUtilityDAO.getContentVersionsByContentDocumentIds(new Set<Id>{contentDocId});

            for (ContentVersion cv : versions) {
                ComboboxOption option = new ComboboxOption();
                option.value = cv.Id;
                // Use PathOnClient for the file name in the label, as it includes the extension
                option.fileName = (String.isNotBlank(cv.PathOnClient)? cv.PathOnClient : cv.Title);
                option.isLatest = cv.IsLatest;
                option.versionURL = cv.VersionDataURL;
                option.label = 'Version ' + cv.VersionNumber;
                option.description = cv.Description;
                option.createdDate = cv.CreatedDate;
                option.reason = cv.ReasonForChange;
                options.add(option);
            }
        }
        return options;
    }
}