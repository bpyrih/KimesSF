public with sharing class DocuSignService {
    
    public static final String DOCUSIGN_NAMED_CREDS = 'callout:DocuSign';
    public static final String COMMON_PATH = '/restapi/v2.1/accounts/' + ConstantUtils.DOCUSING_ACCOUNT_NUMBER;
    public static final String CREATE_ENVELOP_ENDPOINT = DOCUSIGN_NAMED_CREDS + COMMON_PATH + '/envelopes';
    public static final String VIEW_RECIPIENTS_EDPOINT = DOCUSIGN_NAMED_CREDS + COMMON_PATH + '/envelopes/{envelopId}/views/recipient';
    public static final String GET_ENVELOP_EDPOINT = DOCUSIGN_NAMED_CREDS + COMMON_PATH + '/envelopes/{envelopId}';
    public static final String GET_SIGNED_DOCUMENT = DOCUSIGN_NAMED_CREDS + COMMON_PATH + '/envelopes/{envelopId}/documents/{documentId}?encoding=base64';

    public static final Map<String, String> headersMap = new Map<String, String> {'Content-Type' => 'application/json'};
    public static final Map<String, String> headersMapGetDocument = new Map<String, String> {'Content-Type' => 'application/pdf', 'Content-Transfer-Encoding' => 'base64'};
    public static final String POST_METHOD = 'POST';
    public static final String GET_METHOD = 'GET';

    public class CreateEnvelopWrapper {
        public String documentId;
        public String base64Document;
        public String status;
        public ContentDocument document;
        public List<User> signUsers;
        public Document_Sign_Config__c signConfig;
        public SObject signRecord;
    }

    public static String callGetSignDocument(String envelopId, String documentId) {
        String base64Document = docusignCall(
            GET_SIGNED_DOCUMENT.replace('{envelopId}', envelopId).replace('{documentId}', documentId),
                null,
                GET_METHOD, 
                headersMapGetDocument
            );

        return base64Document;
    }

    public static DocuSignDTO.GetEnvelopResponse callGetEnvelop(Work_File__c workFile) {
        DocuSignDTO.GetEnvelopResponse response = (DocuSignDTO.GetEnvelopResponse) JSON.deserialize(
            docusignCall(
                GET_ENVELOP_EDPOINT.replace('{envelopId}', workFile.EnvelopId__c),
                null,
                GET_METHOD, 
                headersMap
            ),
            DocuSignDTO.GetEnvelopResponse.class
        );

        return response;
    }

    public static DocuSignDTO.RecipientViewResponse callRecipientView(Work_File__c workFile) {
        DocuSignDTO.RecipientViewRequest request = new DocuSignDTO.RecipientViewRequest();
        request.email = workFile.Engineer_Sign_User__r.Email;
        request.userName = workFile.Engineer_Sign_User__r.Name;
        request.authenticationMethod = 'none';
        request.clientUserId = '1';
        request.returnUrl = ConstantUtils.VISUAL_FORCE_URL + '/apex/UpdateRecordPage?recordId=' + workFile.Id;

        String strRequest = JSON.serialize(request);
        System.debug(strRequest);

        DocuSignDTO.RecipientViewResponse response = (DocuSignDTO.RecipientViewResponse) JSON.deserialize(
            docusignCall(
                VIEW_RECIPIENTS_EDPOINT.replace('{envelopId}', workFile.EnvelopId__c), 
                JSON.serialize(request), 
                POST_METHOD, 
                headersMap
            ),
            DocuSignDTO.RecipientViewResponse.class
        );

        return response;
    }

    public static DocuSignDTO.EnvelopResponse callCreateEnvelop(CreateEnvelopWrapper createEnvelopWrapper) {
        DocuSignDTO.EnvelopRequest request = createEnvelopRequest(createEnvelopWrapper);
        String strRequest = JSON.serializePretty(request);
        System.debug(strRequest);
        DocuSignDTO.EnvelopResponse response = (DocuSignDTO.EnvelopResponse) JSON.deserialize(
            docusignCall(
                CREATE_ENVELOP_ENDPOINT, 
                JSON.serialize(request), 
                POST_METHOD, 
                headersMap
            ),
            DocuSignDTO.EnvelopResponse.class
        );

        return response;
    }

    public static DocuSignDTO.EnvelopRequest createEnvelopRequest(CreateEnvelopWrapper createEnvelopWrapper) {
        DocuSignDTO.EnvelopRequest request = new DocuSignDTO.EnvelopRequest();
        request.status = createEnvelopWrapper.status;
        request.emailSubject = 'Engineer Signature ' + createEnvelopWrapper.document.Title + '.' + createEnvelopWrapper.document.FileExtension;
        request.setDocument(getSignDocument(createEnvelopWrapper));
        for (User user : createEnvelopWrapper.signUsers) {
            request.setSigner(
                getSignerWithTabs(
                    user, 
                    createEnvelopWrapper,
                    createEnvelopWrapper.signUsers.indexOf(user) + 1
                )
            );
        }

        return request;
    }

    public static DocuSignDTO.EnvelopDocument getSignDocument(CreateEnvelopWrapper createEnvelopWrapper) {
        DocuSignDTO.EnvelopDocument document = new DocuSignDTO.EnvelopDocument();
        document.documentBase64 = createEnvelopWrapper.base64Document;
        document.documentId = createEnvelopWrapper.documentId;
        document.fileExtension = createEnvelopWrapper.document.FileType;
        document.name = createEnvelopWrapper.document.Title + '.' + createEnvelopWrapper.document.FileExtension;
        return document;
    }

    public static DocuSignDTO.Signer getSignerWithTabs(User user, CreateEnvelopWrapper createEnvelopWrapper, Integer userIndex) {
        String index = String.valueOf(userIndex);
        DocuSignDTO.Signer signer = new DocuSignDTO.Signer();
        signer.name = user.Name;
        signer.email = user.Email;
        signer.recipientId = index;
        signer.routingOrder = index;
        signer.clientUserId = index;
        for (Document_Sign_Element__c signElement : createEnvelopWrapper.signConfig.Document_Sign_Elements__r) {
            if (signElement.Element_Type__c == 'Sign') {
                signer.setSignerHereTab(getSignTab(signElement, createEnvelopWrapper.documentId));
            } else if (signElement.Element_Type__c == 'Text') {
                signer.setTextTab(getTextTab(signElement, createEnvelopWrapper));
            } else if (signElement.Element_Type__c == 'Seal') {
                signer.setSealTab(getSealTab(signElement, createEnvelopWrapper.documentId));
            }
        }
        return signer;
    }

    private static DocuSignDTO.SignerHereTab getSignTab(Document_Sign_Element__c signElement, String documentId) {
        DocuSignDTO.SignerHereTab tab = new DocuSignDTO.SignerHereTab();
        tab.documentId = documentId;
        tab.pageNumber = String.valueOf(signElement.Page_Number__c);
        tab.xPosition = String.valueOf(signElement.xPosition__c);
        tab.yPosition = String.valueOf(signElement.yPosition__c);
        return tab;
    }

    private static DocuSignDTO.NotarySealTab getSealTab(Document_Sign_Element__c signElement, String documentId) {
        DocuSignDTO.NotarySealTab tab = new DocuSignDTO.NotarySealTab();
        tab.documentId = documentId;
        tab.pageNumber = String.valueOf(signElement.Page_Number__c);
        tab.xPosition = String.valueOf(signElement.xPosition__c);
        tab.yPosition = String.valueOf(signElement.yPosition__c);
        return tab;
    }

    private static DocuSignDTO.TextTab getTextTab(Document_Sign_Element__c signElement, CreateEnvelopWrapper createEnvelopWrapper) {
        DocuSignDTO.TextTab tab = new DocuSignDTO.TextTab();
        tab.documentId = createEnvelopWrapper.documentId;
        tab.pageNumber = String.valueOf(signElement.Page_Number__c);
        tab.xPosition = String.valueOf(signElement.xPosition__c);
        tab.yPosition = String.valueOf(signElement.yPosition__c);
        tab.height = String.valueOf(signElement.height__c);
        tab.width = String.valueOf(signElement.width__c);
        tab.locked = 'true';
        tab.required = 'false';
        tab.value = getTextValue(signElement.value__c, createEnvelopWrapper.signRecord);
        return tab;
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

    public static String docusignCall(String endpoint, String request, String method, Map<String, String> headers) {
        HttpRequest req= new HttpRequest();
        req.setEndpoint(endpoint); 
        req.setMethod(method);
        if (headers != null) {
            for(String header : headers.keySet()) {
                req.setHeader(header, headers.get(header));
            }
        }
        if (method != GET_METHOD) {
            req.setBody(request);
        }
        

        Http http = new Http();
        
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        return res.getBody();
    }
}