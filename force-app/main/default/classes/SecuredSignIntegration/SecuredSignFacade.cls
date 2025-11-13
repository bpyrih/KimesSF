public with sharing class SecuredSignFacade {
 @AuraEnabled
    public static void startUploadAndSign(Id workFileId, String email, String firstName, String lastName) {
        System.debug('[SSF] startUploadAndSign IN wf=' + workFileId);
        uploadAndSignWorkFileFuture(workFileId, email, firstName, lastName);
    }

@Future(callout=true)
    public static void uploadAndSignWorkFileFuture(
        Id workFileId,
        String email,
        String firstName,
        String lastName
    ) {
        System.debug('[SSF] FUTURE start wf=' + workFileId);
        try {
            Map<String,String> res = doUploadAndSignWorkFile(workFileId, email, firstName, lastName);
            Async_Callout_Notification__e evt = new Async_Callout_Notification__e(
                Status__c  = 'SUCCESS',
                Context__c = (String)workFileId,
                Message__c = JSON.serialize(res)
            );
            EventBus.publish(evt);
        } catch (Exception e) {
            Async_Callout_Notification__e evt = new Async_Callout_Notification__e(
                Status__c  = 'ERROR',
                Context__c = (String)workFileId,
                Message__c = e.getMessage()
            );
            EventBus.publish(evt);
        }
    }


    @AuraEnabled
    public static Map<String, String> uploadAndSendQuotePdf(Id quoteId) {
        System.debug('[SSF] uploadAndSendQuotePdf IN quoteId=' + quoteId);
        try {
            Map<String,String> res = doUploadAndSendQuotePdf(quoteId);
            System.debug('[SSF] uploadAndSendQuotePdf OUT=' + res);
            return res;
        } catch (AuraHandledException e) {
            System.debug('[SSF] uploadAndSendQuotePdf ERROR(Aura)=' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('[SSF] uploadAndSendQuotePdf ERROR=' + e.getMessage());
            throw new AuraHandledException('Secured Signing error: ' + e.getMessage());
        }
    }

    //Work File (embedded)
    private static Map<String, String> doUploadAndSignWorkFile(
        Id workFileId,
        String email,
        String firstName,
        String lastName
    ) {
        if (workFileId == null) {
            throw new AuraHandledException('Work_File__c Id is required.');
        }
        if (String.isBlank(email)) {
            throw new AuraHandledException('Signer email is empty.');
        }

        ContentVersion cv = WorkFileDAO.getLatestVersion(workFileId);
        System.debug('[SSF] latest CV for WF: ' + cv);
        if (cv == null) {
            throw new AuraHandledException('File not found for Work_File__c Id ' + workFileId);
        }

        HttpResponse uploadRes = SecuredSignService.uploadFile(
            cv.VersionData,
            cv.Title + '.' + cv.FileExtension
        );
        System.debug('[SSF] uploadRes status=' + uploadRes.getStatusCode());

        SecuredSignDTO.DocumentUploadResponse uploadDto = parseUpload(uploadRes.getBody());
        String documentRef = uploadDto.Reference;

        HttpResponse smartRes = SecuredSignService.sendSmartTagEmbedded(
            documentRef,
            email,
            firstName,
            lastName,
            URL.getOrgDomainUrl().toExternalForm()
        );
        System.debug('[SSF] smartRes status=' + smartRes.getStatusCode());

        List<SecuredSignDTO.FullSmartTagResponse> smartList = parseSmartTag(smartRes.getBody());
        if (smartList == null || smartList.isEmpty() || smartList[0].Signers == null || smartList[0].Signers.isEmpty()) {
            throw new AuraHandledException('SmartTag response is empty.');
        }

        SecuredSignDTO.ResponseSigner signer = pickSigner(smartList[0].Signers, email);
        if (signer == null || String.isBlank(signer.SigningKey)) {
            throw new AuraHandledException('SigningKey not found in SmartTag response.');
        }

        String weSignUrl   = SecuredSignService.getWeSignUrl();
        String embeddedUrl = toEmbedded(weSignUrl);

        Map<String, String> out = new Map<String, String>();
        out.put('weSignUrl',   embeddedUrl);
        out.put('documentRef', documentRef);
        out.put('signingKey',  signer.SigningKey);
        return out;
    }

    //Quote (email)
    private static Map<String, String> doUploadAndSendQuotePdf(Id quoteId) {
        if (quoteId == null) {
            throw new AuraHandledException('Quote Id is required.');
        }

        Quote q = [
            SELECT Id, Name, ContactId,
                   Contact.FirstName,
                   Contact.LastName,
                   Contact.Email
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
        System.debug('[SSF] Quote loaded: ' + q);

        if (q.ContactId == null) {
            throw new AuraHandledException('Quote has no Contact.');
        }

        String email     = q.Contact.Email;
        String firstName = q.Contact.FirstName;
        String lastName  = q.Contact.LastName;

        if (String.isBlank(email)) {
            throw new AuraHandledException('Contact on Quote has no Email.');
        }

        QuoteDocument qd = [
            SELECT Id, Document, Name, CreatedDate
            FROM QuoteDocument
            WHERE QuoteId = :quoteId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.debug('[SSF] latest QuoteDocument: ' + qd);

        if (qd == null) {
            throw new AuraHandledException('No PDF found in Quote PDFs.');
        }

        HttpResponse uploadRes = SecuredSignService.uploadFile(
            qd.Document,
            qd.Name != null ? qd.Name : (q.Name + '.pdf')
        );
        System.debug('[SSF] Quote uploadRes status=' + uploadRes.getStatusCode() + ', body=' + uploadRes.getBody());

        SecuredSignDTO.DocumentUploadResponse uploadDto = parseUpload(uploadRes.getBody());
        String documentRef = uploadDto.Reference;
        System.debug('[SSF] Quote documentRef=' + documentRef);

        HttpResponse smartRes = SecuredSignService.sendSmartTagEmail(
            documentRef,
            email,
            firstName,
            lastName,
            URL.getOrgDomainUrl().toExternalForm()
        );
        System.debug('[SSF] Quote smartRes status=' + smartRes.getStatusCode() + ', body=' + smartRes.getBody());

        List<SecuredSignDTO.FullSmartTagResponse> smartList = parseSmartTag(smartRes.getBody());
        Integer cnt = (smartList == null) ? 0 : smartList.size();
        System.debug('[SSF] Quote smartList size=' + cnt);
        if (cnt == 0) {
            throw new AuraHandledException('SmartTag response is empty.');
        }

        Map<String, String> out = new Map<String, String>();
        out.put('documentRef', documentRef);
        out.put('status', 'sent');
        return out;
    }

    //helpers

    private static SecuredSignDTO.DocumentUploadResponse parseUpload(String body) {
        System.debug('[SSF] parseUpload body=' + body);
        try {
            return (SecuredSignDTO.DocumentUploadResponse)
                JSON.deserialize(body, SecuredSignDTO.DocumentUploadResponse.class);
        } catch (Exception e) {
            System.debug('[SSF] parseUpload ERROR=' + e.getMessage());
            throw new AuraHandledException('Upload response parse failed: ' + e.getMessage());
        }
    }

    private static List<SecuredSignDTO.FullSmartTagResponse> parseSmartTag(String body) {
        System.debug('[SSF] parseSmartTag body=' + body);
        try {
            return (List<SecuredSignDTO.FullSmartTagResponse>)
                JSON.deserialize(body, List<SecuredSignDTO.FullSmartTagResponse>.class);
        } catch (Exception e) {
            System.debug('[SSF] parseSmartTag ERROR=' + e.getMessage());
            throw new AuraHandledException('SmartTag response parse failed: ' + e.getMessage());
        }
    }

    private static SecuredSignDTO.ResponseSigner pickSigner(
        List<SecuredSignDTO.ResponseSigner> signers,
        String targetEmail
    ) {
        System.debug('[SSF] pickSigner signers=' + signers + ', targetEmail=' + targetEmail);
        if (signers == null || signers.isEmpty()) return null;
        String t = targetEmail == null ? null : targetEmail.trim().toLowerCase();
        if (t != null) {
            for (SecuredSignDTO.ResponseSigner s : signers) {
                if (s.Email != null && s.Email.trim().toLowerCase() == t) {
                    return s;
                }
            }
        }
        return signers[0];
    }

    private static String toEmbedded(String url) {
        if (String.isBlank(url)) return null;
        if (!url.contains('/Utilities/LinkAccess.aspx')) return url;
        return url.replace('/Utilities/LinkAccess.aspx', '/Embedded/Sign.aspx');
    }
}
