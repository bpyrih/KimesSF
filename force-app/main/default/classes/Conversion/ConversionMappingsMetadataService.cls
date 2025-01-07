public with sharing class ConversionMappingsMetadataService {
    public Enum FieldConvertType {
        STANDARD,
        FORMULA,
        CONSTANT
    }
    
    public List<Conversion_Mapping__mdt> conversionMappings {
        get {
            if (this.conversionMappings == null) {
                this.conversionMappings = [SELECT Id, Destination_Field__c, Field_Convert_Type__c, Formula__c, Source_Field__c 
                                        FROM Conversion_Mapping__mdt];
            }

            return this.conversionMappings;
        }
        set;
    }

    public Set<String> getSourceFields() {
        Set<String> sourceFields = new Set<String>();

        for (Conversion_Mapping__mdt mapping : this.conversionMappings) {
            if (FieldConvertType.valueOf(mapping.Field_Convert_Type__c) != FieldConvertType.CONSTANT) {
                sourceFields.add(mapping.Source_Field__c);
            }
        }

        return sourceFields;
    }
}