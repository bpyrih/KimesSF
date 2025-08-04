public with sharing class HTTP_Mock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        String generalPath = DocuSignService.DOCUSIGN_NAMED_CREDS + DocuSignService.COMMON_PATH;

        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        System.debug(req.getEndpoint());
        if (req.getEndpoint().contains('/envelopes/') && req.getEndpoint().contains('/views/recipient')) {
            res.setBody('{'
                + '"url": "https://demo.docusign.net/Member/StartInSession.aspx?"'
                + '}');

        } else if (req.getEndpoint().contains('/envelopes/') && req.getEndpoint().contains('/documents/')) {
            res.setBody('cmVzLnNldEJvZHkoJ3siZXhhbXBsZSI6InRlc3QifScpOw==');
        } else if (req.getEndpoint().contains('/envelopes/')) {
            res.setBody('{'
                + '"status": "sent"' +
                + '}');
        } else if (req.getEndpoint().contains('/envelopes')) {
            res.setBody('{'
                + '"envelopeId": "c754c1a7-8ebf-4fb4-a7de-7e2a38a7250a",'
                + '"status": "sent",'
                + '"statusDateTime": "recipientview",'
                + '"uri": "https://demo.docusign.net/Member/StartInSession.aspx?"'
                + '}');
        } else if (req.getEndpoint().contains('/pdf-with-added-text')) {
            res.setBody('{'
                + '"outputUrl": "https://testurl.com",'
                + '"outputId": "outputIdTest",'
                + '"inputId": "inputIdTest",'
                + '"message": "hsucess"'
                + '}');
        } else if (req.getEndpoint().contains('/resource/')) {
            res.setBodyAsBlob(Blob.valueOf('Test file content 2'));
        }

        return res;
    } 
}