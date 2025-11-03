public with sharing class SecuredSignFacade {

    @AuraEnabled
    public static Map<String, String> uploadAndSignWorkFile(
        Id workFileId,
        String email,
        String firstName,
        String lastName
    ) {
        try {
            return doUploadAndSignWorkFile(workFileId, email, firstName, lastName);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Secured Signing error: ' + e.getMessage());
        }
    }

    private static Map<String, String> doUploadAndSignWorkFile(
        Id workFileId,
        String email,
        String firstName,
        String lastName
    ) {
        if (workFileId == null) {
            throw new AuraHandledException('Work_File__c Id is required.');
        }

        ContentVersion cv = WorkFileDAO.getLatestVersion(workFileId);
        if (cv == null) {
            throw new AuraHandledException('File not found for Work_File__c Id ' + workFileId);
        }

        HttpResponse uploadRes = SecuredSignService.uploadFile(
            cv.VersionData,
            cv.Title + '.' + cv.FileExtension
        );

        SecuredSignDTO.DocumentUploadResponse uploadDto;
        try {
            uploadDto = (SecuredSignDTO.DocumentUploadResponse)
                JSON.deserialize(uploadRes.getBody(), SecuredSignDTO.DocumentUploadResponse.class);
        } catch (Exception e) {
            throw new AuraHandledException('Upload response parse failed: ' + e.getMessage());
        }

        if (uploadDto == null || String.isBlank(uploadDto.Reference)) {
            throw new AuraHandledException('Upload succeeded but DocumentReference is missing.');
        }

        String documentRef = uploadDto.Reference;

        HttpResponse smartRes = SecuredSignService.sendSmartTag(
            documentRef,
            email,
            firstName,
            lastName,
            URL.getOrgDomainUrl().toExternalForm()
        );

        List<SecuredSignDTO.FullSmartTagResponse> smartList;
        try {
            smartList = (List<SecuredSignDTO.FullSmartTagResponse>)
                JSON.deserialize(smartRes.getBody(), List<SecuredSignDTO.FullSmartTagResponse>.class);
        } catch (Exception e) {
            throw new AuraHandledException('SmartTag response parse failed: ' + e.getMessage());
        }

        if (smartList == null || smartList.isEmpty()) {
            throw new AuraHandledException('SmartTag response is empty.');
        }

        SecuredSignDTO.ResponseSigner signer = pickSigner(smartList[0].Signers, email);
        if (signer == null || String.isBlank(signer.SigningKey)) {
            throw new AuraHandledException('SigningKey not found in SmartTag response.');
        }

        String weSignUrl = SecuredSignService.getWeSignUrl();
        String embeddedUrl = toEmbedded(weSignUrl);

        Map<String, String> out = new Map<String, String>();
        out.put('weSignUrl', embeddedUrl);
        out.put('documentRef', documentRef);
        out.put('signingKey', signer.SigningKey);
        return out;
    }

    private static SecuredSignDTO.ResponseSigner pickSigner(
        List<SecuredSignDTO.ResponseSigner> signers,
        String targetEmail
    ) {
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
