@isTest
public class WorkFileSignControllerTest {
    @TestSetup
    static void testSetup() {
        
        Document_Sign_Config__c dsc = new Document_Sign_Config__c(Document_Sign_Template__c = 'ANSI Engineering', Display_Name__c = 'Test Config');
        insert dsc;

        List<Document_Sign_Element__c> signElems = new List<Document_Sign_Element__c>();

        signElems.add(new Document_Sign_Element__c(
            Document_Sign_Config__c = dsc.Id, 
            Element_Type__c = 'Text',
            height__c = 120,
            width__c = 120,
            scaleValue__c = 2,
            value__c = 'texttext',
            xPosition__c = 1082,
            yPosition__c = 46,
            Page_Number__c = 1
        ));
        signElems.add(new Document_Sign_Element__c(
            Document_Sign_Config__c = dsc.Id, 
            Element_Type__c = 'Text',
            height__c = 120,
            width__c = 120,
            scaleValue__c = 2,
            value__c = 'texttext',
            xPosition__c = 1082,
            yPosition__c = 46,
            Page_Number__c = 1
        ));
        signElems.add(new Document_Sign_Element__c(
            Document_Sign_Config__c = dsc.Id, 
            Element_Type__c = 'Text',
            height__c = 120,
            width__c = 120,
            scaleValue__c = 2,
            value__c = 'texttext',
            xPosition__c = 1082,
            yPosition__c = 46,
            Page_Number__c = 1
        ));
        signElems.add(new Document_Sign_Element__c(
            Document_Sign_Config__c = dsc.Id, 
            Element_Type__c = 'Text',
            height__c = 120,
            width__c = 120,
            scaleValue__c = 2,
            value__c = 'texttext {Opportunity__r.Name}',
            xPosition__c = 1082,
            yPosition__c = 46,
            Page_Number__c = 1
        ));

        insert signElems;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            AccountId = testAccount.Id, 
            StageName = 'Draft', 
            Project_Name__c = 'Test Project',
            CloseDate = System.today()
        );
        insert testOpportunity;

        Work_File__c wf = new Work_File__c(Opportunity__c=testOpportunity.Id, Status__c='Draft', Document_Sign_Template__c='ANSI Engineering', Engineer_Sign_User__c=System.UserInfo.getUserId());
        insert wf;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'Test_File.pdf',
            VersionData = Blob.valueOf('Test file content'),
            IsMajorVersion = true
        );
        insert testContentVersion;

        testContentVersion = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :testContentVersion.Id
        ];

        ContentDocument testContentDocument = [
            SELECT Id FROM ContentDocument WHERE Id = :testContentVersion.ContentDocumentId
        ];

        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = wf.Id,
            ContentDocumentId = testContentDocument.Id,
            ShareType = 'V'
        );
        insert testContentDocumentLink;
    }

    @IsTest
    static void testUpdateAndRedirect(){    
        Work_File__c wf = [SELECT Id FROM Work_File__c LIMIT 1];
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HTTP_Mock());
        WorkFileSignController.sentReview(wf.Id);
        Test.stopTest();
    }

}