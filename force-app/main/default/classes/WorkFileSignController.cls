public with sharing class WorkFileSignController {
    private static final ContentDocumentUtilityDAO contentDocumentUtilityDAO = new ContentDocumentUtilityDAO();

    @AuraEnabled
    public static String sentReview(Id workFileId) {
        Work_File__c workFile = getWorkFile(workFileId);

        if (String.isBlank(workFile.EnvelopId__c)) {
            DocuSignService.CreateEnvelopWrapper wrapper = generateDocumentData(workFile);
            if (wrapper.signUsers == null || wrapper.signConfig == null || wrapper.document == null) {
                return '';
            }

            DocuSignDTO.EnvelopResponse envelopResponse = DocuSignService.callCreateEnvelop(wrapper);
            workFile.EnvelopId__c = envelopResponse.envelopeId;
        }

        DocuSignDTO.RecipientViewResponse recipientResponse = DocuSignService.callRecipientView(workFile);
        workFile.SignURL__c = recipientResponse.url;

        update workFile;

        return workFile.SignURL__c;
    }

    public static DocuSignService.CreateEnvelopWrapper generateDocumentData(Work_File__c workFile) {
        DocuSignService.CreateEnvelopWrapper createEnvelopWrapper = new DocuSignService.CreateEnvelopWrapper();
        createEnvelopWrapper.status = 'sent';
        createEnvelopWrapper.signUsers = new List<User> {workFile.Engineer_Sign_User__r};
        createEnvelopWrapper.documentId = '1';
        createEnvelopWrapper.signRecord = workFile;
        List<ContentDocumentLink> sourceFiles = contentDocumentUtilityDAO.getContentDocumentLinksByLinkedEntityIdsAndExtensions(new List<Id> {workFile.Id}, new List<String> {'pdf'});

        if (sourceFiles.size() > 0) {
            
            Id cvId = sourceFiles[0].ContentDocument.LatestPublishedVersionId;
            List<ContentVersion> conVersions = contentDocumentUtilityDAO.getContentVersionByIds(new Set<Id> {cvId});

            createEnvelopWrapper.document = sourceFiles[0].ContentDocument;
            createEnvelopWrapper.base64Document = EncodingUtil.base64Encode(conVersions[0].VersionData);

            if (workFile.Document_Sign_Template__c != null) {
                Document_Sign_Config__c signConfig = getDocumentSignConfig(workFile.Document_Sign_Template__c);

                createEnvelopWrapper.signConfig = signConfig;
            }
        }

        return createEnvelopWrapper;
    }

    public static Document_Sign_Config__c getDocumentSignConfig(String fileSignType) {
        return [
            SELECT Id, (SELECT Page_Number__c, Element_Type__c, xPosition__c, yPosition__c, height__c, width__c, value__c, scaleValue__c FROM Document_Sign_Elements__r)
            FROM Document_Sign_Config__c 
            WHERE Document_Sign_Template__c =: fileSignType
        ];
    }

    public static Work_File__c getWorkFile(Id workFileId) {
        Work_File__c workFile = [
            SELECT Id, Status__c, EnvelopId__c, SignURL__c, Engineer_Sign_User__r.Name, Engineer_Sign_User__r.Email, Opportunity__r.Project_Name__c, Document_Sign_Template__c, Opportunity__r.Name
            FROM Work_File__c
            WHERE Id = :workFileId
        ];

        return workFile;
    }

}