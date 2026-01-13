@isTest
public with sharing class PDFRestServiceTest {
    public static Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('ANSI').getRecordTypeId();
    
    @isTest
    public static void callGetAnnotatedFileTest() {
        Test.setMock(HttpCalloutMock.class, new HTTP_Mock());
        Document_Sign_Config__c config = new Document_Sign_Config__c(
            Document_Sign_Template__c = 'ANSI Engineering',
            Config_Fields__c = 'Field1,Field2'
        );
        insert config;

        Document_Sign_Element__c element = new Document_Sign_Element__c(
            Document_Sign_Config__c = config.Id,
            Page_Number__c = 1,
            xPosition__c = 100,
            yPosition__c = 200,
            width__c = 150,
            value__c = 'TestValue {Opportunity__r.Project_Name__c}',
            Rotation__c=90,
            Element_Type__c = 'Text'
        );
        insert element;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opp', Project_Name__c = 'Test Project Name', AccountId = acc.Id, StageName = 'Draft', CloseDate = System.today(), RecordTypeId = recordTypeId);
        insert opp;

        Work_File__c testRecord = new Work_File__c(Name = 'Test Work File', Opportunity__c = opp.Id, Status__c = 'Draft', Document_Sign_Template__c='ANSI Engineering', Engineer_Sign_User__c=System.UserInfo.getUserId());
        insert testRecord;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Project Name',
            PathOnClient = 'Test Project Name.pdf',
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
            LinkedEntityId = testRecord.Id,
            ContentDocumentId = testContentDocument.Id,
            ShareType = 'V'
        );
        insert testContentDocumentLink;

        Test.startTest();
        Id newVersionId = PDFRestService.annotateWorkFile(testRecord.Id);
        Test.stopTest();
        System.Assert.isNotNull(newVersionId);
        // System.Assert.areEqual(testContentDocumentLink.ContentDocumentId, newVersionId);
    }
}