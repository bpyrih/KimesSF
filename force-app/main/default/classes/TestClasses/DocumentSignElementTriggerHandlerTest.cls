@isTest
public class DocumentSignElementTriggerHandlerTest {
    @IsTest
    static void triggerTest() {
        Document_Sign_Config__c dsc = new Document_Sign_Config__c(Document_Sign_Template__c = 'ANSI Engineering', Display_Name__c = 'Test DSC');
        insert dsc;

        List<Document_Sign_Element__c> signElems = new List<Document_Sign_Element__c>();

        signElems.add(new Document_Sign_Element__c(
            Document_Sign_Config__c = dsc.Id, 
            Element_Type__c = 'Text',
            height__c = 120,
            width__c = 120,
            scaleValue__c = 2,
            value__c = 'texttext {Opportunity__c}',
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

        signElems.get(0).value__c = 'test';
        
        update signElems;
    }
}