public with sharing class ConstantUtils {
    public static final String VISUAL_FORCE_URL = Org_Variable__mdt.getInstance('VisualForceURL')?.Value__c;
    public static final String DOCUSING_ACCOUNT_NUMBER = Org_Variable__mdt.getInstance('DocusignAccountNumber')?.Value__c;

    public static List<String> getWordsInCurlyBraces(String input) {
        List<String> results = new List<String>();
        
        if (String.isBlank(input)) {
            return results;
        }
        
        String regex = '\\{[^}]*\\}';
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        
        while (matcher.find()) {
            results.add(matcher.group());
        }
        
        return results;
    }

    public static Object getFieldValue(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }
        
        String[] fieldParts = fieldPath.split('\\.');
        SObject currentObject = record;
        
        for (Integer i = 0; i < fieldParts.size() - 1; i++) {
            String fieldName = fieldParts[i];
            currentObject = (SObject) currentObject.getSObject(fieldName);
            if (currentObject == null) {
                return null;
            }
        }
        
        String finalFieldName = fieldParts[fieldParts.size() - 1];
        return currentObject.get(finalFieldName);
    }

    public static Boolean validateRelationshipPath(String relationshipPath, String sObjectName) {
        try {
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
            if (sObjectType == null) {
                return false;
            }

            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

            String[] fields = relationshipPath.split('\\.');

            for (Integer i = 0; i < fields.size(); i++) {
                String field = fields[i].toLowerCase().replace('__r', '__c');
                if (!field.contains('__c') && i != fields.size() - 1) {
                    field = field + 'id';
                }

                Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

                if (!fieldMap.containsKey(field)) {
                    return false;
                }

                if (i == fields.size() - 1) {
                    return true;
                }

                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(field).getDescribe();
                if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                    if (!referenceTo.isEmpty()) {
                        describeResult = referenceTo[0].getDescribe();
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('Error validating relationship path: ' + e.getMessage());
            return false;
        }

        return true;
    }
}