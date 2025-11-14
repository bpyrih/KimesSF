@RestResource(urlMapping='/SecuredSignQuoteCallback/*')
global without sharing class SecuredSignQuoteCallback {

    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;

        String quoteId = req.params.get('quoteId');
        System.debug('[@SS_CB] quoteId=' + quoteId);

        if (String.isBlank(quoteId)) {
            System.debug('[@SS_CB] quoteId is blank, return 200');
            RestContext.response.statusCode = 200;
            return;
        }

        String statusParam = req.params.get('Status');
        String eventParam  = req.params.get('Event');
        String docRef      = req.params.get('Doc');
        if (String.isBlank(docRef)) docRef = req.params.get('DocumentReference');
        if (String.isBlank(docRef)) docRef = req.params.get('Ref');

        System.debug('[@SS_CB] incoming params: Status=' + statusParam + ', Event=' + eventParam + ', Doc=' + docRef);

        Quote q = [
            SELECT Id, Name, Status
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        System.debug('[@SS_CB] quote loaded: ' + q.Id + ' / ' + q.Name + ' / ' + q.Status);

        Boolean isFinal = false;

        if (!String.isBlank(statusParam)) {
            if (statusParam == 'Signed'
                || statusParam == '1 of 1 Signed'
                || (statusParam.endsWith('Signed') && !statusParam.startsWith('0 of'))) {
                isFinal = true;
            }
        }
        if (!String.isBlank(eventParam)) {
            if (eventParam.equalsIgnoreCase('Completed')
                || eventParam.equalsIgnoreCase('Complete')
                || eventParam.equalsIgnoreCase('Signed')) {
                isFinal = true;
            }
        }

        if (isFinal && !String.isBlank(docRef)) {
            System.debug('[@SS_CB] final event, download doc ref=' + docRef);
            try {
                Blob pdfBlob = SecuredSignService.getSignedDocumentBlob(docRef);
                System.debug('[@SS_CB] downloaded blob size=' + (pdfBlob != null ? pdfBlob.size() : 0));

                String fileName = 'Signed ' + (q.Name != null ? q.Name : 'Quote');

                ContentVersion cv = new ContentVersion();
                cv.Title        = fileName;
                cv.PathOnClient = fileName + '.pdf';
                cv.VersionData  = pdfBlob;
                insert cv;
                System.debug('[@SS_CB] CV inserted=' + cv.Id);

                Id cdId = [
                    SELECT ContentDocumentId
                    FROM ContentVersion
                    WHERE Id = :cv.Id
                ].ContentDocumentId;
                System.debug('[@SS_CB] CD=' + cdId);

                insert new ContentDocumentLink(
                    ContentDocumentId = cdId,
                    LinkedEntityId    = q.Id,
                    ShareType         = 'V',
                    Visibility        = 'AllUsers'
                );
                System.debug('[@SS_CB] CDL inserted');
            } catch (Exception e) {
                System.debug('[@SS_CB] download/attach error=' + e.getMessage());
            }
        } else {
            System.debug('[@SS_CB] not final or no docRef, skip file creation');
        }

        if (isFinal) {
            try {
                q.Status = 'Accepted';
                update q;
                System.debug('[@SS_CB] quote updated to Accepted');
            } catch (Exception e) {
                System.debug('[@SS_CB] quote update error=' + e.getMessage());
            }
        } else {
            System.debug('[@SS_CB] status not final: ' + (String.isBlank(statusParam) ? eventParam : statusParam));
        }

        RestContext.response.statusCode = 200;
        System.debug('[@SS_CB] done 200');
    }
}
