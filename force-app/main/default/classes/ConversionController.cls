public class ConversionController {
    private static ConversionService conversionService = new ConversionService();

    @AuraEnabled
    public static Id convertCaseToLead(Id caseId) {
        try {
            Id leadId = conversionService.convertCaseToLead(caseId, true).Id;
            conversionService.markCaseAsConverted(caseId, leadId, null);
            return leadId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Id convertCaseToOpportunity(Id caseId) {
        try {
            Id leadId = conversionService.convertCaseToLead(caseId, true).Id;
            Id oppId = conversionService.convertLeadToOpportunity(leadId);
            conversionService.markCaseAsConverted(caseId, leadId, oppId);
            return oppId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}