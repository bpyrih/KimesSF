public with sharing class DocumentSignConfigController {
    private static List<Document_Sign_Config__c> templates;
    private static Map<String, Document_Sign_Config__c> templatesMapByName;

    public static Document_Sign_Config__c getTempateByName(String templateName) {
        getAllTemplates();
        if (templatesMapByName == null) {
            templatesMapByName = new Map<String, Document_Sign_Config__c>();
            for (Document_Sign_Config__c config : templates) {
                templatesMapByName.put(config.Document_Sign_Template__c, config);
            }
        }

        return templatesMapByName.get(templateName);
    }

    private static void getAllTemplates() {
        if (templates == null) {
            templates = [
                SELECT Id, Document_Sign_Template__c, Config_Fields__c,
                (SELECT Id, Document_Sign_Config__c, Page_Number__c, xPosition__c,Rotation__c, yPosition__c, width__c, value__c, Element_Type__c FROM Document_Sign_Elements__r)
                FROM Document_Sign_Config__c
            ];
        }
    }
}