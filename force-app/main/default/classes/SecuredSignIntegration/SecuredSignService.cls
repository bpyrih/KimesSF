public with sharing class SecuredSignService {
    
    private static final String BASE_URL = 'callout:SecuredSign';
    private static final String REFERER = URL.getOrgDomainUrl().toExternalForm();
    
    public static HttpResponse uploadFile(Blob fileBody, String fileName) {
        String boundary = '----SecuredSignBoundary' + Datetime.now().getTime();
        Map<String, String> headers = buildHeaders();
        headers.put('Content-Type', 'multipart/form-data; boundary=' + boundary);
        
        Blob body = buildMultipartBody(fileBody, fileName, boundary);
        
        HttpRequest req = buildHttpRequest(BASE_URL + '/Web/v1.4/Document/Uploader', 'POST', headers);
        req.setBodyAsBlob(body);
        // req.setTimeout(20000);
        System.debug('=== HttpRequest Debug ===');
        System.debug('Endpoint: ' + req.getEndpoint());
        System.debug('Method: ' + req.getMethod());
        System.debug('Body Size: ' + (body != null ? body.size() : 0));
        System.debug('=========================');
        
        return executeRequest(req);
    }
    
    
    public static HttpResponse sendSmartTag(
        String documentRef,
    String email,
    String firstName,
    String lastName,
    String returnUrl
    ) {
        Map<String, String> headers = buildHeaders();
        headers.put('Content-Type', 'application/json');
        
        Map<String, Object> payload = buildSmartTagPayload(
            documentRef, email, firstName, lastName, returnUrl );
        
        HttpRequest req = buildHttpRequest(BASE_URL + '/Web/v1.4/SmartTag/Send', 'POST', headers);
        req.setBody(JSON.serialize(payload));
        System.debug('SMARTTAG REQUEST Body: ' + req.getBody());
        
        return executeRequest(req);
    }
    
    
    private static HttpRequest buildHttpRequest(String url, String method, Map<String,String> headers) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        for (String key : headers.keySet()) req.setHeader(key, headers.get(key));
        return req;
    }
    
    
    private static Map<String,Object> buildSmartTagPayload(
        String documentRef, String email, String firstName, String lastName, String returnUrl
    ){
        return new Map<String,Object>{
            'DocumentReferences' => new List<String>{ documentRef },
            'DisableBroadcast'   => true,
            'SelectOnly'         => false,
            'Embedded'           => true,
            'NoInvitationEmailTemplate' => true,
            'DueDate'            => Date.today().addDays(3).format(),
            'NotifyUrl'          => returnUrl,
            'Signers' => new List<Object>{
                new Map<String,Object>{
                    'FirstName' => firstName,
                    'LastName'  => lastName,
                    'Email'     => email
                }
            }
        };
    }
    
    
    private static Blob buildMultipartBody(Blob fileBody, String fileName, String boundary) {
        String CRLF = '\r\n';
        
        String filePartHeader = '--' + boundary + CRLF +
            'Content-Disposition: form-data; name="AnyThing"; filename="' + fileName + '"' + CRLF +
            'Content-Type: application/octet-stream' + CRLF + CRLF;
        
        String folderPart = CRLF + '--' + boundary + CRLF +
            'Content-Disposition: form-data; name="Folder"' + CRLF + CRLF +
            'InBox';
        
        String closingPart = CRLF + '--' + boundary + '--';
        
        String hexBody = EncodingUtil.convertToHex(Blob.valueOf(filePartHeader)) +
            EncodingUtil.convertToHex(fileBody) +
            EncodingUtil.convertToHex(Blob.valueOf(folderPart)) +
            EncodingUtil.convertToHex(Blob.valueOf(closingPart));
        
        return EncodingUtil.convertFromHex(hexBody);
    }
    
    public static String getUIResourceFileUrl(Integer resourceType) {
        Map<String, String> headers = buildHeaders();
        headers.put('Content-Type', 'application/json');
        HttpRequest req = buildHttpRequest(BASE_URL + '/Web/v1.4/UI/Resource2/16', 'GET', headers);
        System.debug('UI/Resource2 request body: ' + req.getBody());
        HttpResponse res = executeRequest(req);
        System.debug('UI/Resource2 response body: ' + res.getBody());
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('UI/Resource2 failed: ' + res.getStatusCode() + ' ' + res.getBody());
        }
        
        SecuredSignDTO.UIResourceResponse dto;
        try {
            dto = (SecuredSignDTO.UIResourceResponse) JSON.deserialize(res.getBody(), SecuredSignDTO.UIResourceResponse.class);
        } catch (Exception e) {
            throw new AuraHandledException('UI/Resource2 parse error: ' + e.getMessage() + ' Body: ' + res.getBody());
        }
        
        if (dto == null) return null;
        if (!String.isBlank(dto.Url)) return dto.Url;
        if (dto.FileInfo != null) {
            if (!String.isBlank(dto.FileInfo.FileUrl)) return dto.FileInfo.FileUrl;
            if (!String.isBlank(dto.FileInfo.Url))     return dto.FileInfo.Url;
        }
        return null;
    }
    
    
    public static Blob getSignedDocumentBlob(String documentRef) {
        if (String.isBlank(documentRef)) {
            throw new AuraHandledException('DocumentReference is empty');
        }
        
        Map<String, String> headers = buildHeaders();
        String url = BASE_URL + '/Web/v1.4/Download/GetDocumentData/' +
            EncodingUtil.urlEncode(documentRef, 'UTF-8');
        
        HttpRequest req = buildHttpRequest(url, 'GET', headers);
        Http h = new Http();
        HttpResponse res = h.send(req);
        
        if (res.getStatusCode() == 200) {
            Blob fileBlob = res.getBodyAsBlob();
            return fileBlob;
        } else if (res.getStatusCode() == 404) {
            throw new AuraHandledException('Document not found in Secured Signing (retention).');
        } else {
            throw new AuraHandledException(
                'Secured Signing download failed: ' + res.getStatusCode() + ' ' + res.getBody()
                );
        }
    }
    
    
    private static Map<String, String> buildHeaders() {
        Decimal tsDecimal = Datetime.now().getTime() / 1000;
        Long timestamp = tsDecimal.setScale(0, RoundingMode.FLOOR).longValue();
        
        String nonce = generateNonce(16);
        
        // Secured_Sign_Variables__mdt config = [
        //     SELECT ApiKey__c, ApiSecret__c
        //     FROM Secured_Sign_Variables__mdt
        //     WHERE DeveloperName = 'SecuredSign'
        //     LIMIT 1
        // ];
        String apiKey = getApiKey();
        String apiSecret = getApiSecret();
        String stringToSign = apiKey + '\n' + timestamp + '\n' + nonce;
        String signature = createSignature(stringToSign, apiSecret);
        
        return new Map<String, String>{
            'Accept' => 'application/json',
            'Referer' => REFERER,
            'X-CUSTOM-API-KEY' => apiKey,
            'X-CUSTOM-DATE' => String.valueOf(timestamp),
            'X-CUSTOM-NONCE' => nonce,
            'X-CUSTOM-SIGNATURE' => signature
        };
    }
    
    @AuraEnabled(cacheable=true)
    public static String getApiKey() {
        Secured_Sign_Variables__mdt config = [
        SELECT ApiKey__c FROM Secured_Sign_Variables__mdt
        WHERE DeveloperName = 'SecuredSign' LIMIT 1
    ];
        return config.ApiKey__c;
    }
    @AuraEnabled(cacheable=true)
    public static String getApiSecret() {
        Secured_Sign_Variables__mdt config = [
        SELECT ApiSecret__c FROM Secured_Sign_Variables__mdt
        WHERE DeveloperName = 'SecuredSign' LIMIT 1
    ];
        return config.ApiSecret__c;
    }
    
    private static HttpResponse executeRequest(HttpRequest req) {
        Http http = new Http();
        return http.send(req);
    }
    
    private static String generateNonce(Integer length) {
        final String chars = '0123456789abcdef';
        String res = '';
        for (Integer i = 0; i < length; i++) {
            Integer rand = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            res += chars.substring(rand, rand + 1);
        }
        return res;
    }
    
    
    private static String createSignature(String data, String secret) {
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(data),Blob.valueOf(secret) );
        return EncodingUtil.base64Encode(mac);
    }
}