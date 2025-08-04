public with sharing class PDFRestService {
    public static final String PDF_REST_URL = Org_Variable__mdt.getInstance('PDFRestUrl')?.Value__c;
    private static final String PDF_WIHT_ADDED_TEXT_ENDPOINT = PDF_REST_URL + '/pdf-with-added-text';
    private static final String GET_FILE_ENDPOINT = PDF_REST_URL + '/resource/{0}?format=file';

    private static final String PDF_REST_API_KEY = Org_Variable__mdt.getInstance('PDFRestKey')?.Value__c;
    
    public static Id callGetAnnotatedFile(PDFRestDTO.PDFWithAddedTextResponse pdfWithAddressRestResponse) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(GET_FILE_ENDPOINT.replace('{0}', pdfWithAddressRestResponse.outputId));
        req.setMethod('GET');
        req.setHeader('Accept', 'application/pdf');
        req.setHeader('Api-Key', PDF_REST_API_KEY);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('PDF created successfully: ' + res.getBody());
            Id annoatatedVersionId = PDFRestHelper.createAnnotatedVersion(pdfWithAddressRestResponse, res.getBodyAsBlob());
            return annoatatedVersionId;
        } else {
            System.debug('Failed to create PDF: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
        }
    }

    public static PDFRestDTO.PDFWithAddedTextResponse callSendPdfForAnnotation(Id workFileId) {

        String textOptions = JSON.serialize(PDFRestHelper.getAddedTextFields(workFileId));
        System.debug(textOptions);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(PDF_WIHT_ADDED_TEXT_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Api-Key', PDF_REST_API_KEY);

        PDFRestDTO.FileWrapper fileWrapper = PDFRestHelper.getFileData(workFileId);
        fileWrapper.fields = new Map<String, String>{
            'text_objects' => textOptions,
            'output' => fileWrapper.fileName
        };

        PDFRestHelper.setRequestFileData(req, fileWrapper);

        System.debug(fileWrapper);

        // Send the request
        Http http = new Http();
        HTTPResponse res = http.send(req);

        // Handle the response
        if (res.getStatusCode() == 200) {
            PDFRestDTO.PDFWithAddedTextResponse resp = (PDFRestDTO.PDFWithAddedTextResponse) JSON.deserialize(res.getBody(), PDFRestDTO.PDFWithAddedTextResponse.class);
            System.debug(resp);
            System.debug('PDF created successfully: ' + res.getBody());
            resp.sfWorkFileId = workFileId;
            resp.sfFileName = fileWrapper.fileName;
            resp.sfFileId = fileWrapper.fileId;
            return resp;
        } else {
            System.debug('Failed to create PDF: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
        }
    }

    @AuraEnabled
    public static Id annotateWorkFile(Id workFileId) {

        PDFRestDTO.PDFWithAddedTextResponse resp1 = callSendPdfForAnnotation(workFileId);
        Id annotatedVersionId = callGetAnnotatedFile(resp1);

        PDFRestHelper.updateWorkFileForAnnotated(workFileId);

        return annotatedVersionId;
    }
}