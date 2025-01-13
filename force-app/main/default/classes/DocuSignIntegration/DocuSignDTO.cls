public class DocuSignDTO {
    public class EnvelopRequest {
        public List<EnvelopDocument> documents;
        public EnvelopRecipients recipients = new EnvelopRecipients();

        public String emailSubject;
        public String status;

        public void setDocument(EnvelopDocument envelopDocument) {
            if (documents == null) {
                documents = new List<EnvelopDocument>();
            }

            documents.add(envelopDocument);
        }

        public void setSigner(Signer signer) {
            if (recipients.signers == null) {
                recipients.signers = new List<Signer>();
            }

            recipients.signers.add(signer);
        }
    }

    public class EnvelopDocument {
        public String documentBase64;
        public String documentId;
        public String fileExtension;
        public String name;
    }

    public class EnvelopRecipients {
        public List<Signer> signers;
    }
    
    public class Signer {
        public String name;
        public String email;
        public String recipientId;
        public String routingOrder;
        public String clientUserId;
        public SignTabs tabs = new SignTabs();

        public void setSignerHereTab(SignerHereTab signerHereTab) {
            if (tabs.signHereTabs == null) {
                tabs.signHereTabs = new List<SignerHereTab>();
            }
            
            tabs.signHereTabs.add(signerHereTab);
        }

        public void setTextTab(TextTab textTab) {
            if (tabs.textTabs == null) {
                tabs.textTabs = new List<TextTab>();
            }
            
            tabs.textTabs.add(textTab);
        }

        public void setSealTab(NotarySealTab sealTab) {
            if (tabs.notarySealTabs == null) {
                tabs.notarySealTabs = new List<NotarySealTab>();
            }
            
            tabs.notarySealTabs.add(sealTab);
        }
    }

    public class SignTabs {
        public List<SignerHereTab> signHereTabs;
        public List<NotarySealTab> notarySealTabs;
        public List<TextTab> textTabs;
    }

    public class SignerHereTab {
        public String documentId;
        public String pageNumber;
        public String xPosition;
        public String yPosition;
        public String stampType;
        public String scaleValue;
    }

    public class NotarySealTab {
        public String documentId = '1';
        public String pageNumber = '1';
        public String xPosition = '150';
        public String yPosition = '150';
    }

    public class TextTab {
        public String documentId = '1';
        public String pageNumber;
        public String xPosition;
        public String yPosition;
        public String height;
        public String width ;
        public String required;
        public String locked;
        public String value;
    }


    public class EnvelopResponse {
        public String envelopeId;
        public String uri;
        public String statusDateTime;
        public String status;
    }

    //----------------


    public class RecipientViewRequest {
        public String email = 'andrii.makarchuk99@gmail.com';
        public String authenticationMethod = 'none';
        public String userName = 'Andrii Makarchuk';
        public String clientUserId = '1000';
        public String returnUrl;
    }

    public class RecipientViewResponse {
        public String url;
    }

    public class GetEnvelopResponse {
        public String status;
    }
}