public class SecuredSignDTO {
    
    public class DocumentUploadResponse {
        public String Reference;
    }
    
    
    public class SmartTagSendRequest {
        public List<String> DocumentReferences;
        public Boolean Embedded;
        public Datetime DueDate;
        public String ReturnUrl;
        public List<Signer> Signers;
        
        public void addDocumentReference(String ref) {
            if (DocumentReferences == null) DocumentReferences = new List<String>();
            DocumentReferences.add(ref);
        }
        
        public void addSigner(Signer s) {
            if (Signers == null) Signers = new List<Signer>();
            Signers.add(s);
        }
    }
    
    public class Signer {
        public String FirstName;
        public String LastName;
        public String Email;
        public String ClientReference;
        public Boolean Embedded;
        public String ReturnUrl;
        public List<InviteeCoordinate> InviteeCoordinates;
        
        public void addCoordinate(InviteeCoordinate c) {
            if (InviteeCoordinates == null) InviteeCoordinates = new List<InviteeCoordinate>();
            InviteeCoordinates.add(c);
        }
    }
    
    public class InviteeCoordinate {
        public Integer PageNumber;
        public Decimal X;
        public Decimal Y;
        public Decimal Width;
        public Decimal Height;
        public String Type;
    }
    
    public class FullSmartTagResponse {
        public String Name;
        public String Reference;
        public String Status;
        public List<ResponseSigner> Signers;
    }
    
    
    public class ResponseSigner {
        public String SigningKey;
        public String SignerReference;
        public String FirstName;
        public String LastName;
        public String Email;
    }
    public class SmartTagSendResponse {
        public String SigningKey;
        public String SignerReference;
    }
    
    
    public class ErrorResponse {
        public String Code;
        public String Message;
    }
}