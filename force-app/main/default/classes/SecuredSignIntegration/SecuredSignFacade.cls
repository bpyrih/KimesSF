public with sharing class SecuredSignFacade {
    
    @AuraEnabled
    public static Map<String, String> uploadAndSignWorkFile(
        Id workFileId,
    String email,
    String firstName,
    String lastName,
    Decimal x,
    Decimal y,
    Decimal width,
    Decimal height
    ) {
        Map<String, String> result = new Map<String, String>();
        
        
        ContentVersion cv = WorkFileDAO.getLatestVersion(workFileId);
        if (cv == null) {
            throw new AuraHandledException('File not found for Work_File__c Id ' + workFileId);
        }
        
        
        HttpResponse uploadResponse = SecuredSignService.uploadFile(cv.VersionData, cv.Title + '.' + cv.FileExtension);
        System.debug('UPLOAD RESPONSE STATUS: ' + uploadResponse.getStatusCode());
        System.debug('UPLOAD RESPONSE BODY: ' + uploadResponse.getBody());
        
        SecuredSignDTO.DocumentUploadResponse uploadResult = null;
        String documentRef = null;
        
        
        if (String.isNotBlank(uploadResponse.getBody())) {
            
            try {
                uploadResult = (SecuredSignDTO.DocumentUploadResponse) JSON.deserialize(
                    uploadResponse.getBody(),
                SecuredSignDTO.DocumentUploadResponse.class
                    );
                System.debug('UPLOAD RESULT REFERENCE: ' + uploadResponse.getBody());
                if (uploadResult != null) {
                    documentRef = uploadResult.Reference;
                }
            } catch (Exception e) {
                System.debug('Could not parse response body. Error: ' + e.getMessage());
            }
        }
        if (String.isBlank(documentRef)) {
            throw new AuraHandledException('Upload file failed. Could not retrieve DocumentReference. Status: ' + uploadResponse.getStatusCode() + '. Body: ' + uploadResponse.getBody());
        }
        
        System.debug('SUCCESS! Document Reference retrieved: ' + documentRef);
        
        HttpResponse smartTagResponse = SecuredSignService.sendSmartTag(
            documentRef,
        email,
        firstName,
        lastName,
        URL.getOrgDomainUrl().toExternalForm(),
        x,
        y,
        width,
        height
            );
        if (smartTagResponse.getStatusCode() != 200) {
            throw new AuraHandledException('SmartTag send failed: ' + smartTagResponse.getBody());
        }
        
        SecuredSignDTO.ResponseSigner signerDetails;
        try {
            List<SecuredSignDTO.FullSmartTagResponse> fullResponseList =
                (List<SecuredSignDTO.FullSmartTagResponse>) JSON.deserialize(
                smartTagResponse.getBody(),
            List<SecuredSignDTO.FullSmartTagResponse>.class
            
                );
System.debug('SMARTTAG RESPONSE Body: ' + smartTagResponse.getBody());
            
            if (fullResponseList != null && !fullResponseList.isEmpty()) {
                SecuredSignDTO.FullSmartTagResponse resultSmartTag = fullResponseList[0];

                if (resultSmartTag.Signers != null && !resultSmartTag.Signers.isEmpty()) {
                    signerDetails = resultSmartTag.Signers[0];
                }
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error parsing SmartTag response: ' + e.getMessage());
        }
        
        if (signerDetails == null || String.isBlank(signerDetails.SigningKey)) {
            throw new AuraHandledException('Could not retrieve SigningKey from the API response.');
        }
        
        
        result.put('documentRef', documentRef);
        result.put('signingKey', signerDetails.SigningKey);
        System.debug('SUCCESS! Document Reference retrieved: ' + documentRef);
        System.debug('SUCCESS! Document Reference retrieved: ' + signerDetails.SigningKey);

        
        return result;
    }
}