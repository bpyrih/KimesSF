public class SS_UpdateRecordController {
    public Id recordId { get; set; }
    public String eventType { get; set; }
    public String docRef { get; set; }
    
    public SS_UpdateRecordController() {
        recordId  = ApexPages.currentPage().getParameters().get('recordId');
        eventType = ApexPages.currentPage().getParameters().get('event');
        docRef    = ApexPages.currentPage().getParameters().get('docRef');
    }
    
    public PageReference updateAndRedirect() {
        if (recordId == null) return null;
        try {
            Work_File__c wf = [
                SELECT Id, Status__c, EnvelopId__c, SignURL__c,
                       Opportunity__c, Opportunity__r.Delivery_Method__c
                FROM Work_File__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            Boolean isFinalEvent =
                eventType != null &&
                eventType != 'decline' &&
                eventType != 'cancel' &&
                eventType != 'ttl_expired';
            
            if (isFinalEvent) {
                wf.Status__c = 'Signed';
                
                List<ContentDocumentLink> pdfLinks =
                    new ContentDocumentUtilityDAO()
                    .getContentDocumentLinksByLinkedEntityIdsAndExtensions(
                new List<Id>{ wf.Id },
                new List<String>{ 'pdf' }
                );
                
                String downloadKey = docRef != null ? docRef : wf.EnvelopId__c;
                Blob signedPdfBlob =
                    downloadKey != null ? SecuredSignService.getSignedDocumentBlob(downloadKey) : null;
                
                if (signedPdfBlob != null) {
                    String prefix = 'Signed';
                    if (wf.Opportunity__r != null &&
                    wf.Opportunity__r.Delivery_Method__c == 'Hard Copy') {
                        prefix = 'Modified';
                        wf.Status__c = 'Review';
                    }
                    
                    if (!pdfLinks.isEmpty()) {
                        ContentDocumentLink baseLink = pdfLinks[0];
                        addVersionToDocument(
                            baseLink.ContentDocumentId,
                        baseLink.ContentDocument.Title,
                        prefix,
                        signedPdfBlob
                            );
                    } else {
                        Id newDocId = createContentDocument('Signed Document', prefix, signedPdfBlob);
                        createLinks(newDocId, new List<Id>{ wf.Id });
                    }
                }
            }
            
            if (eventType == 'decline') {
                wf.EnvelopId__c = null;
                wf.SignURL__c   = null;
                wf.Status__c    = 'Declined';
            }
            
            update wf;
            
            String base = URL.getOrgDomainUrl().toExternalForm();
            PageReference pr = new PageReference(base + '/' + recordId);
            pr.setRedirect(true);
            return pr;
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
    public static void addVersionToDocument(Id contentDocumentId, String title, String prefix, Blob dataBlob) {
        ContentVersion cv = new ContentVersion();
        cv.ContentDocumentId = contentDocumentId;
        cv.Title        = prefix + ' ' + title;
        cv.VersionData  = dataBlob;
        cv.PathOnClient = prefix + ' ' + title + '.pdf';
        insert cv;
    }
    
    public static Id createContentDocument(String title, String prefix, Blob dataBlob) {
        ContentVersion cv = new ContentVersion();
        cv.Title        = prefix + ' ' + title;
        cv.VersionData  = dataBlob;
        cv.PathOnClient = prefix + ' ' + title + '.pdf';
        cv.Is_Latest_Signed__c = true;
        insert cv;
        
        return [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ].ContentDocumentId;
    }
    
    public static void createLinks(Id contentDocumentId, List<Id> linkedEntityIds) {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Id entId : linkedEntityIds) {
            if (entId == null) continue;
            links.add(new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
            LinkedEntityId    = entId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
                ));
        }
        insert links;
    }
}