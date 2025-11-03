public with sharing class SecuredSignService {
    private static final String NC_BASE        = 'callout:SecuredSign';
    private static final String API_ROOT       = '/Web/v1.4';
    private static final String UPLOAD_PATH    = '/Document/Uploader';
    private static final String SMARTTAG_PATH  = '/SmartTag/Send';
    private static final String WESIGN_PATH    = '/UI/Resource2/16';
    private static final String DOWNLOAD_PATH  = '/Download/GetDocumentData/';
    private static final String FORM_FOLDER    = 'InBox';
    
    // ---------- public --
    
    public static HttpResponse uploadFile(Blob fileBody, String fileName) {
        assertNotNull(fileBody, 'File body is empty');
        assertNotBlank(fileName, 'File name is empty');
        
        String boundary = '----SecuredSignBoundary' + Datetime.now().getTime();
        Map<String, String> headers = buildAuthHeaders();
        headers.put('Content-Type', 'multipart/form-data; boundary=' + boundary);
        
        Blob multipart = buildMultipartBody(fileBody, fileName, boundary);
        
        HttpRequest req = buildRequest(
            NC_BASE + API_ROOT + UPLOAD_PATH,
        'POST',
        headers
            );
        req.setBodyAsBlob(multipart);
        
        HttpResponse res = send(req);
        ensure2xx(res, 'Upload file failed');
        return res;
    }
    
    public static HttpResponse sendSmartTag(
        String documentRef,
    String email,
    String firstName,
    String lastName,
    String notifyUrl
    ) {
        assertNotBlank(documentRef, 'DocumentReference is empty');
        assertNotBlank(email, 'Signer email is empty');
        
        Map<String, String> headers = buildAuthHeaders();
        headers.put('Content-Type', 'application/json');
        
        Map<String, Object> payload = buildSmartTagPayload(
            documentRef, email, firstName, lastName, notifyUrl
            );
        
        HttpRequest req = buildRequest(
            NC_BASE + API_ROOT + SMARTTAG_PATH,
        'POST',
        headers
            );
        req.setBody(JSON.serialize(payload));
        
        HttpResponse res = send(req);
        ensure200(res, 'SmartTag send failed');
        return res;
    }
    
    public static String getWeSignUrl() {
        Map<String, String> headers = buildAuthHeaders();
        HttpRequest req = buildRequest(
            NC_BASE + API_ROOT + WESIGN_PATH,
        'GET',
        headers
            );
        HttpResponse res = send(req);
        ensure200(res, 'UI Resource request failed');
        
        SecuredSignDTO.UIResourceResponse dto;
        try {
            dto = (SecuredSignDTO.UIResourceResponse)
                JSON.deserialize(res.getBody(), SecuredSignDTO.UIResourceResponse.class);
        } catch (Exception e) {
            throw makeAura('UI Resource parse error: ' + e.getMessage());
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
        assertNotBlank(documentRef, 'DocumentReference is empty');
        
        Map<String, String> headers = buildAuthHeaders();
        String url = NC_BASE + API_ROOT + DOWNLOAD_PATH + EncodingUtil.urlEncode(documentRef, 'UTF-8');
        
        HttpRequest req = buildRequest(url, 'GET', headers);
        HttpResponse res = send(req);
        
        if (res.getStatusCode() == 200) {
            return res.getBodyAsBlob();
        }
        if (res.getStatusCode() == 404) {
            throw makeAura('Document not found in Secured Signing (retention).');
        }
        throw makeAura('Download failed: ' + res.getStatusCode() + ' ' + res.getBody());
    }
    
    // ---------- internal ---
    
    private static HttpRequest buildRequest(String url, String method, Map<String,String> headers) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        for (String k : headers.keySet()) {
            req.setHeader(k, headers.get(k));
        }
        return req;
    }
    
    private static HttpResponse send(HttpRequest req) {
        Http h = new Http();
        return h.send(req);
    }
    
    private static Map<String, Object> buildSmartTagPayload(
        String documentRef,
    String email,
    String firstName,
    String lastName,
    String notifyUrl
    ) {
        return new Map<String, Object>{
            'DocumentReferences'        => new List<String>{ documentRef },
            'DisableBroadcast'          => true,
            'SelectOnly'                => false,
            'Embedded'                  => true,
            'NoInvitationEmailTemplate' => true,
            'DueDate'                   => Date.today().addDays(3).format(),
            'NotifyUrl'                 => notifyUrl,
            'Signers'                   => new List<Object>{
                new Map<String, Object>{
                    'FirstName' => firstName,
                    'LastName'  => lastName,
                    'Email'     => email
                }
            }
        };
    }
    
    private static Blob buildMultipartBody(Blob fileBody, String fileName, String boundary) {
        String CRLF = '\r\n';
        
        String head =
            '--' + boundary + CRLF +
            'Content-Disposition: form-data; name="AnyThing"; filename="' + fileName + '"' + CRLF +
            'Content-Type: application/octet-stream' + CRLF + CRLF;
        
        String folder =
            CRLF + '--' + boundary + CRLF +
            'Content-Disposition: form-data; name="Folder"' + CRLF + CRLF +
            FORM_FOLDER;
        
        String tail = CRLF + '--' + boundary + '--';
        
        String hex =
            EncodingUtil.convertToHex(Blob.valueOf(head)) +
            EncodingUtil.convertToHex(fileBody) +
            EncodingUtil.convertToHex(Blob.valueOf(folder)) +
            EncodingUtil.convertToHex(Blob.valueOf(tail));
        
        return EncodingUtil.convertFromHex(hex);
    }
    
    private static Map<String, String> buildAuthHeaders() {
        Long ts = Datetime.now().getTime() / 1000;
        String nonce = generateNonce(16);
        
        String apiKey    = getApiKey();
        String apiSecret = getApiSecret();
        
        String toSign = apiKey + '\n' + String.valueOf(ts) + '\n' + nonce;
        String signature = sign(toSign, apiSecret);
        
        return new Map<String, String>{
            'Accept'             => 'application/json',
            'Referer'            => URL.getOrgDomainUrl().toExternalForm(),
            'X-CUSTOM-API-KEY'   => apiKey,
            'X-CUSTOM-DATE'      => String.valueOf(ts),
            'X-CUSTOM-NONCE'     => nonce,
            'X-CUSTOM-SIGNATURE' => signature
        };
    }
    
    @AuraEnabled(cacheable=true)
    public static String getApiKey() {
        Secured_Sign_Variables__mdt cfg = [
            SELECT ApiKey__c
            FROM Secured_Sign_Variables__mdt
            WHERE DeveloperName = 'SecuredSign'
            LIMIT 1
        ];
        return cfg.ApiKey__c;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getApiSecret() {
        Secured_Sign_Variables__mdt cfg = [
            SELECT ApiSecret__c
            FROM Secured_Sign_Variables__mdt
            WHERE DeveloperName = 'SecuredSign'
            LIMIT 1
        ];
        return cfg.ApiSecret__c;
    }
    
    private static String generateNonce(Integer length) {
        final String chars = '0123456789abcdef';
        String out = '';
        for (Integer i = 0; i < length; i++) {
            Integer r = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            out += chars.substring(r, r + 1);
        }
        return out;
    }
    
    private static String sign(String data, String secret) {
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(data), Blob.valueOf(secret));
        return EncodingUtil.base64Encode(mac);
    }
    
    private static void ensure200(HttpResponse res, String msg) {
        if (res.getStatusCode() != 200) {
            throw makeAura(msg + ': ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
    
    private static void ensure2xx(HttpResponse res, String msg) {
        Integer c = res.getStatusCode();
        if (c < 200 || c >= 300) {
            throw makeAura(msg + ': ' + c + ' ' + res.getBody());
        }
    }
    
    private static void assertNotBlank(String v, String msg) {
        if (String.isBlank(v)) {
            throw makeAura(msg);
        }
    }
    
    private static void assertNotNull(Object v, String msg) {
        if (v == null) {
            throw makeAura(msg);
        }
    }
    
    private static AuraHandledException makeAura(String msg) {
        return new AuraHandledException(msg);
    }
}