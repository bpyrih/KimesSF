public with sharing class DocumentSignElementTriggerHandler {

    public static void beforeInsert(List<Document_Sign_Element__c> newDocSignElements) {
        validateRecordFieldValues(newDocSignElements);
        validateFields(newDocSignElements);
    }

    public static void beforeUpdate(List<Document_Sign_Element__c> newDocSignElements, Map<Id, Document_Sign_Element__c> oldDocSignElementsMap) {
        validateRecordFieldValues(newDocSignElements);
        validateFields(newDocSignElements);
    }

    public static void afterInsert(List<Document_Sign_Element__c> newDocSignElements) {
        setFields(newDocSignElements);
    } 

    public static void afterUpdate(List<Document_Sign_Element__c> newDocSignElements, Map<Id, Document_Sign_Element__c> oldDocSignElementsMap) {
        setFields(newDocSignElements);
    } 

    public static void validateFields(List<Document_Sign_Element__c> newDocSignElements) {
        for (Document_Sign_Element__c newDocSignElement : newDocSignElements) {
            List<String> fieldList = new List<String>();
            for (String field : ConstantUtils.getWordsInCurlyBraces(newDocSignElement.value__c)) {
                String formatedField = field.replace('{', '').replace('}', '');
                if (!ConstantUtils.validateRelationshipPath(formatedField, 'Work_File__c')) {
                    newDocSignElement.value__c.addError(formatedField + ' is not valid field on Work File object!');
                }
            }
        }
    }

    private static void setFields(List<Document_Sign_Element__c> newDocSignElements) {
        Map<Id, Document_Sign_Element__c> docSignMap = new Map<Id, Document_Sign_Element__c>(newDocSignElements);

        Set<Id> docConfigIds = new Set<Id>();
        for (Document_Sign_Element__c newDocSignElement : newDocSignElements) {
            docConfigIds.add(newDocSignElement.Document_Sign_Config__c);
        }

        List<Document_Sign_Config__c> configs = [
            SELECT Id, Config_Fields__c, 
            (SELECT Id, value__c FROM Document_Sign_Elements__r)
            FROM Document_Sign_Config__c WHERE Id IN :docConfigIds
        ];
        
        for (Document_Sign_Config__c config : configs) {
            Set<String> fields = new Set<String>();

            for (Document_Sign_Element__c dse : config.Document_Sign_Elements__r) {
                List<String> fieldList;
                if (docSignMap.containsKey(dse.Id)) {
                    fieldList = ConstantUtils.getWordsInCurlyBraces(docSignMap.get(dse.Id).value__c);
                } else {
                    fieldList = ConstantUtils.getWordsInCurlyBraces(dse.value__c);
                }

                for (String field : fieldList) {
                    fields.add(field.replace('{', '').replace('}', ''));
                }
                
            }
            config.Config_Fields__c = String.join(fields, ',');
        }

        update configs;
    }

    public static void validateRecordFieldValues(List<Document_Sign_Element__c> newList) {
        for (Document_Sign_Element__c dse : newList) {
            if (dse.scaleValue__c < 0.5 || dse.scaleValue__c > 2.0) {
                dse.scaleValue__c.addError('This field accept values form 0.5 to 2.0');
            }
        }
    }
}