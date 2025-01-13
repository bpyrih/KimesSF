public class ConversionService {
    private static final String COMPLETED_STATUS = 'Closed';
    private static final ConversionMappingsMetadataService convMappingMetadataService = new ConversionMappingsMetadataService();
    private static final SObjectUtility OPPORTUNITY_UTILITY = new SObjectUtility('Opportunity');

    private static final Map<String, String> REQUEST_TYPE_TO_OPPORTUNITY_RT = new Map<String, String> {
        null => OPPORTUNITY_UTILITY.devNameToIdMap.get('ANSI'),
        'ANSI + Standards' => OPPORTUNITY_UTILITY.devNameToIdMap.get('ANSI'),
        'Residential Drafting' => OPPORTUNITY_UTILITY.devNameToIdMap.get('Residential_Drafting'),
        'Commercial Drafting' => OPPORTUNITY_UTILITY.devNameToIdMap.get('Commercial_Engineering'),
        'Engineering Tasks' => OPPORTUNITY_UTILITY.devNameToIdMap.get('ANSI')
    };

    public Lead convertCaseToLead(Id caseId) {
        Case caseToConvert = new CaseDAO().getCaseById(caseId, convMappingMetadataService.getSourceFields());
        Lead convertedLead = new Lead();
        for(Conversion_Mapping__mdt mapping : convMappingMetadataService.conversionMappings) {
            ConversionMappingsMetadataService.FieldConvertType convertType = ConversionMappingsMetadataService.FieldConvertType.valueOF(mapping.Field_Convert_Type__c);
            Object mapValue;
            if (convertType == ConversionMappingsMetadataService.FieldConvertType.STANDARD) {
                mapValue = caseToConvert.get(mapping.Source_Field__c);
            } else if (convertType == ConversionMappingsMetadataService.FieldConvertType.FORMULA) {
                mapValue = getValueByFormula(mapping.Formula__c, caseToConvert);
            } else if (convertType == ConversionMappingsMetadataService.FieldConvertType.CONSTANT) {
                mapValue = mapping.Source_Field__c;
            }
            convertedLead.put(mapping.Destination_Field__c, mapValue);
        }
        return convertedLead;
    }

    public Lead convertCaseToLead(Id caseId, Boolean isInsert) {
        Lead convertedLead = this.convertCaseToLead(caseId);
        if(isInsert) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult sr2 = Database.insert(convertedLead, dml);
        }
        this.assignFilesFromRecordToRecord(caseId, convertedLead.Id);
        this.assignActivitiesFromRecordToRecord(caseId, convertedLead.Id);
        return convertedLead;
    }

    private Object getValueByFormula(String formula, SObject record) {
        FormulaEval.FormulaInstance ff = System.Formula.builder()
            .withReturnType(FormulaEval.FormulaReturnType.STRING)
            .withType(Case.SObjectType)
            .withFormula(formula)
            .build();
        
        return ff.evaluate(record);
    }

    public void markCaseAsConverted(Id caseId, Id leadId, Id opportunityId) {
        Case updateCase = new Case(Id = caseId, Converted_Lead__c = leadId, Status = COMPLETED_STATUS, Opportunity__c = opportunityId);
        update updateCase;
    }

    public Id convertLeadToOpportunity(Id leadId) {
        Lead leadToConvert = new LeadDAO().getLeadById(leadId);
        Contact convertContact = new ContactDAO().getContactByEmail(leadToConvert.Email);
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setContactId(convertContact?.Id);
        lc.setAccountId(convertContact?.AccountId);

        LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.ApiName);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        update new Opportunity(
            Id = lcr.getOpportunityId(), 
            RecordTypeId = REQUEST_TYPE_TO_OPPORTUNITY_RT.get(leadToConvert.Request_Type__c)   
        );

        return lcr.getOpportunityId();
    }

    private void assignFilesFromRecordToRecord(Id sourceId, Id targetId) {
        List<ContentDocumentLink> files = new List<ContentDocumentLink>();
        
        List<ContentDocumentLink> sourceFiles = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :sourceId];
        for (ContentDocumentLink file : sourceFiles) {
            files.add(new ContentDocumentLink(
                ContentDocumentId = file.ContentDocumentId,
                LinkedEntityId = targetId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }

        insert files;
    }

    public void assignActivitiesFromRecordToRecord(Id sourceId, Id targetId) {
        List<Task> tasks = [SELECT Subject, Status, Priority, Description, OwnerId, ActivityDate, TaskSubtype
                        FROM Task
                        WHERE WhatId = :sourceId];
                        
        List<Event> events = [SELECT Subject, Location, StartDateTime, EndDateTime, Description, OwnerId, EventSubtype
                            FROM Event
                            WHERE WhatId = :sourceId];

        // Clone Tasks
        List<Task> clonedTasks = new List<Task>();
        for (Task task : tasks) {
            Task newTask = task.clone(false, true, false, false);
            newTask.WhatId = null; // Update WhatId to the target record
            newTask.WhoId = targetId; // Update WhatId to the target record
            clonedTasks.add(newTask);
        }

        // Clone Events
        List<Event> clonedEvents = new List<Event>();
        for (Event event : events) {
            Event newEvent = event.clone(false, true, false, false);
            newEvent.WhatId = null; // Update WhatId to the target record
            newEvent.WhoId = targetId; // Update WhatId to the target record
            clonedEvents.add(newEvent);
        }

        // Insert cloned records
        if (!clonedTasks.isEmpty()) {
            insert clonedTasks;
        }
        if (!clonedEvents.isEmpty()) {
            insert clonedEvents;
        }
    }
}