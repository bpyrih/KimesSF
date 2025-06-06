public class UpdateRecordController {
    public Id recordId { get; set; }
    public String event;
    public UpdateRecordController() {
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        event = ApexPages.currentPage().getParameters().get('event');
    }

    public PageReference updateAndRedirect() {
        if (recordId != null) {
            try {
                System.debug(event);
                Work_File__c recordToUpdate = [SELECT Id, Status__c, EnvelopId__c, SignURL__c, Opportunity__c, Opportunity__r.Delivery_Method__c FROM Work_File__c WHERE Id = :recordId LIMIT 1];

                if (event != 'decline' && event != 'cancel' && event != 'ttl_expired') {
                    recordToUpdate.Status__c = 'Signed';

                    ContentDocumentLink cdl = new ContentDocumentUtilityDAO().getContentDocumentLinksByLinkedEntityIdsAndExtensions(new List<Id>{recordToUpdate.Id}, new List<String>{'pdf'})[0];

                    String documentBase64String = DocuSignService.callGetSignDocument(recordToUpdate.EnvelopId__c, '1');

                    String prefix = 'Signed';
                    if (recordToUpdate.Opportunity__r.Delivery_Method__c == 'Hard Copy') {
                        prefix = 'Modified';
                        recordToUpdate.Status__c = 'Review';
                    }

                    Id cdID = createContentDocument(cdl.ContentDocument.Title, prefix, documentBase64String);
                    createLinks(cdID, new List<Id>{recordToUpdate.Id, recordToUpdate.Opportunity__c});

                    delete cdl;
                }
                
                if (event == 'decline') {
                    recordToUpdate.EnvelopId__c = null;
                    recordToUpdate.SignURL__c = null;
                }
                update recordToUpdate;
                PageReference redirect = new PageReference('/' + recordId);
                redirect.setRedirect(true);
                return redirect;
            } catch (Exception e) {
                System.debug(e.getMessage());
                System.debug('exception happens');
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating record: ' + e.getMessage()));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Record ID is missing.'));
        }

        return null;
    }

    public static Id createContentDocument(String title, String prefix, String documentBase64String) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = prefix + ' ' + title;
        contentVersion.VersionData = EncodingUtil.base64Decode(documentBase64String);
        contentVersion.PathOnClient = prefix + ' ' + title + '.pdf';
        insert contentVersion;

        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
    }

    public static void createLinks(Id contentDocumentId, List<Id> linkedEntityIds) {
        List<ContentDocumentLink> cdLinks = new List<ContentDocumentLink>();
        for (Id entityId : linkedEntityIds) {
            cdLinks.add(new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = entityId,
                ShareType = 'I',
                Visibility = 'AllUsers'
            ));
        }

        insert cdLinks;
    }
}