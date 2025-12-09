public with sharing class PDFRestHelper {
    public static final String BOUNDARY = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
    private static final ContentDocumentUtilityDAO contentDocumentUtilityDAO = new ContentDocumentUtilityDAO();
    private static final WorkFileDAO workFileDAO = new WorkFileDAO();

    public static void updateWorkFileForAnnotated(ID workFileId) {
        Work_File__c wf = new Work_File__c(Id=workFileId, Status__c = 'Annotated');
        update wf;
    }
    
    public static Id createAnnotatedVersion(PDFRestDTO.PDFWithAddedTextResponse addedTextResponse, Blob documentBase64String) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = addedTextResponse.sfFileName;
        contentVersion.VersionData = documentBase64String;
        contentVersion.Description = 'Annotated Version';
        contentVersion.ReasonForChange = 'Annotated Version';
        contentVersion.PathOnClient = addedTextResponse.sfFileName + '.pdf';
        contentVersion.ContentDocumentId = addedTextResponse.sfFileId;
        insert contentVersion;
        return contentVersion.Id;
    }

    public static PDFRestDTO.FileWrapper getFileData(String recordId) { 
        PDFRestDTO.FileWrapper fileWrapper = new PDFRestDTO.FileWrapper();

        List<ContentDocumentLink> sourceFiles = contentDocumentUtilityDAO.getContentDocumentLinksByLinkedEntityIdsAndExtensions(new List<Id> {recordId}, new List<String> {'pdf'});

        if (sourceFiles.size() > 0) {
            Id cvId = sourceFiles[0].ContentDocument.LatestPublishedVersionId;
            List<ContentVersion> conVersions = contentDocumentUtilityDAO.getContentVersionByIds(new Set<Id> {cvId});

            fileWrapper.fileName = sourceFiles[0].ContentDocument.Title;
            fileWrapper.fileBlob = conVersions[0].VersionData;
            fileWrapper.fileId = conVersions[0].ContentDocumentId;
        }

        return fileWrapper;
    }

    public static List<PDFRestDTO.PDFWithAddedTextFieldData> getAddedTextFields(Id workFileId) {
        Work_File__c workFile = workFileDAO.getWorkFilesByIds(new Set<Id> {workFileId})[0];

        Document_Sign_Config__c dsc = DocumentSignConfigController.getTempateByName(workFile.Document_Sign_Template__c);

        workFile = workFileDAO.getWorkFile(workFileId, new Set<String>(String.isNotBlank(dsc.Config_Fields__c) ? dsc.Config_Fields__c?.split(',') : new List<String> {'Id'}));

        List<PDFRestDTO.PDFWithAddedTextFieldData> pdfFields = new List<PDFRestDTO.PDFWithAddedTextFieldData>();

        for (Document_Sign_Element__c dse : dsc.Document_Sign_Elements__r) {
            PDFRestDTO.PDFWithAddedTextFieldData pdfWithAddedTextFieldData = new PDFRestDTO.PDFWithAddedTextFieldData();
            pdfWithAddedTextFieldData.max_width = String.valueOf(dse.width__c);
            if (String.isNotBlank(dse.value__c)) {
                pdfWithAddedTextFieldData.text = getTextValue(dse.value__c, workFile);
            }
            pdfWithAddedTextFieldData.x = String.valueOf(dse.xPosition__c);
            pdfWithAddedTextFieldData.y = String.valueOf(dse.yPosition__c);
            pdfWithAddedTextFieldData.rotation = String.valueOf(dse.Rotation__c);
            pdfWithAddedTextFieldData.page = String.valueOf(dse.Page_Number__c);
            pdfFields.add(pdfWithAddedTextFieldData);
        }

        return pdfFields;
    }

    private static String getTextValue(String templateValue, SObject record) {
        String newTextValue = templateValue;
        List<String> fields = ConstantUtils.getWordsInCurlyBraces(newTextValue);
        if (!fields.isEmpty()) {
            for (String field : fields) {
                String fieldPath = field.replace('{', '').replace('}', '');
                Object value = ConstantUtils.getFieldValue(record, fieldPath);
                String fieldValue = value != null ? String.valueOf(value) : '';
                System.debug(fieldPath);
                System.debug(fieldValue);
                newTextValue = newTextValue.replace(
                    field, 
                    fieldValue
                );
            }
        }
        return newTextValue;
    }

    public static HttpRequest setRequestFileData(HttpRequest req, PDFRestDTO.FileWrapper fileData) {
        Blob encodingBlob = buildMultipartBody(fileData);

        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + BOUNDARY);
        req.setHeader('Content-Length', String.valueOf(encodingBlob.size()));

        req.setBodyAsBlob(encodingBlob);
        
        return req;
    }

    private static Blob buildMultipartBody(PDFRestDTO.FileWrapper fileData) { 
        String prefix = '--' + BOUNDARY + '\r\n' +
        'Content-Disposition: form-data; name="file"; filename="' + fileData.fileName + '.pdf' + '"\r\n' +
        'Content-Type: ' + fileData.contentType + '\r\n\r\n';
        String suffix = '\r\n--' + BOUNDARY;
        String end1 = '--\r\n';

        // Convert prefix and suffix to hex
        String hexBody = EncodingUtil.convertToHex(Blob.valueOf(prefix));
        hexBody += EncodingUtil.convertToHex(fileData.fileBlob);
        hexBody += EncodingUtil.convertToHex(Blob.valueOf(suffix));

        // Add additional text fields
        if (fileData.fields != null) {
            for (String key : fileData.fields.keySet()) {
                String part = '\r\nContent-Disposition: form-data; name="' + key + '"\r\n\r\n' + fileData.fields.get(key) + '\r\n--' + BOUNDARY;
                hexBody += EncodingUtil.convertToHex(Blob.valueOf(part));
            }
        }
        hexBody += EncodingUtil.convertToHex(Blob.valueOf(end1));

        return EncodingUtil.convertFromHex(hexBody);
    }
}