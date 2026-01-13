@IsTest
global class SecuredSignHttpMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndpoint();
        System.debug('SecuredSignHttpMock endpoint=' + endpoint);
        if (endpoint.contains('/Document/Uploader')) {
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Reference":"DOC-REF-123"}');
        }
        else if (endpoint.contains('/SmartTag/Send')) {
            String body =
                '[' +
                '  {' +
                '    "Name":"Test SmartTag",' +
                '    "Reference":"ST-REF-1",' +
                '    "Status":"Pending",' +
                '    "Signers":[{' +
                '      "SigningKey":"SIGN-KEY-123",' +
                '      "SignerReference":"SR1",' +
                '      "FirstName":"Test",' +
                '      "LastName":"User",' +
                '      "Email":"test@example.com"' +
                '    }]' +
                '  }' +
                ']';
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
        }
        else if (endpoint.contains('/UI/Resource2')) {
            String body =
                '{' +
                '  "Url":"https://dummy.securedsigning.com/Utilities/LinkAccess.aspx",' +
                '  "Name":"UI",' +
                '  "FileInfo":null,' +
                '  "ContentType":"application/json",' +
                '  "StatusCode":"200",' +
                '  "StatusDescription":"OK"' +
                '}';
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
        }
        else if (endpoint.contains('/Download/GetDocumentData')) {
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/pdf');
            res.setBodyAsBlob(Blob.valueOf('PDFDATA_SIGNED'));
        }
        else {
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ok":true}');
        }

        return res;
    }
}
