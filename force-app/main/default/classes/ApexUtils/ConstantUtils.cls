public with sharing class ConstantUtils {
    public static final String AUTHORIZATION_HEADER = 'Authorization';
    public static final String CONTENT_TYPE_HEADER = 'Content-Type';
    public static final String APPLICATION_JSON_VALUE = 'application/json';
    public static final String BEARER_TOKEN_PREFIX = 'Bearer ';
    public static final String GET_METHOD = 'GET';

    public static final String EMPTY_STRING = '';
    public static final String QUESTION_SIGN = '?';
    public static final String EQUAL_SIGN = '=';
    public static final String AMPERSAND_SIGN = '&';
    public static final String DOUBLE_QUOTE_SIGN = '"';

    public static final String LIMIT_VALUE = 'limit';
    public static final String DATE_VALUE = 'date';
    public static final String TYPE_VALUE = 'type';
    public static final String LIST_VALUE = 'list';
    
    public static final Map<String, String> JSON_FIELD_TO_UPDATED_FIELD_MAP = new Map<String, String> {
        LIMIT_VALUE => 'limit_x',
        DATE_VALUE => 'date_x',
        TYPE_VALUE => 'type_x',
        LIST_VALUE => 'list_x'
    };

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