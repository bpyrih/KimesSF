public with sharing class SObjectUtility {
    private String objectName;
    private SObjectType sObjectType;

    public Map<String, Id> devNameToIdMap {
        get {
            if (this.devNameToIdMap == null) {
                this.devNameToIdMap = getDevNameToIdMap();
            }

            return this.devNameToIdMap;
        }
        set;
    }

    public SObjectUtility(String objectName) {
        this.objectName = objectName;
        this.sObjectType = Schema.getGlobalDescribe().get(objectName);
    }

    private Map<String, Id> getDevNameToIdMap() {
        Map<String, Id> returnMap = new Map<String, Id>();

        List<Schema.RecordTypeInfo> recordTypeInfos = sObjectType.getDescribe().getRecordTypeInfos();
        for (Schema.RecordTypeInfo recordTypeInfo : recordTypeInfos) {
            returnMap.put(recordTypeInfo.getDeveloperName(), recordTypeInfo.getRecordTypeId());
        }
        
        return returnMap;
    }
}