public class ConversionService {
    private static final Map<String, String> CASE_PRIORITY_TO_LEAD_RATING = new Map<String, String> {
        'High' => 'Hot',
        'Medium' => 'Warm',
        'Low' => 'Cold'
    };

    private static final String COMPLETED_STATUS = 'Completed';

    public Lead convertCaseToLead(Id caseId) {
        Case caseToConvert = new CaseDAO().getCaseById(caseId);
        Lead convertedLead = new Lead(
            FirstName = '',
            LastName = caseToConvert.SuppliedName,
            Company = caseToConvert.SuppliedCompany,
            Phone = caseToConvert.SuppliedPhone,
            Email = caseToConvert.SuppliedEmail,
            Rating = CASE_PRIORITY_TO_LEAD_RATING.get(caseToConvert.Priority),
            Request_Type__c = caseToConvert.Request_Type__c,
            Client_Billing_Info__c = caseToConvert.Client_Billing_Info__c,
            Client_Type__c = caseToConvert.Client_Type__c,
            Lot_Number__c = caseToConvert.Lot_Number__c,
            Delivery_Method__c = caseToConvert.Delivery_Method__c,
            Flood_Zone__c = caseToConvert.Flood_Zone__c,
            Project_Address__c = caseToConvert.Project_Address__c,
            Property_Owner__c = caseToConvert.Property_Owner__c,
            Receive_Date__c = caseToConvert.Receive_Date__c,
            Converted_Case__c = caseId
        );

        return convertedLead;
    }

    public void markCaseAsConverted(Id caseId, Id leadId, Id opportunityId) {
        Case updateCase = new Case(Id = caseId, Converted_Lead__c = leadId, Status = COMPLETED_STATUS, Opportunity__c = opportunityId);
        update updateCase;
    }

    public Lead convertCaseToLead(Id caseId, Boolean isInsert) {
        Lead convertedLead = this.convertCaseToLead(caseId);
        if(isInsert) {
            insert convertedLead;
        }
        return convertedLead;
    }

    public Id convertLeadToOpportunity(Id leadId) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);

        LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.ApiName);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        return lcr.getOpportunityId();
    }
}