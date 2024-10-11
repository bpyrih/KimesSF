public class CaseDAO {
    public List<Case> getCasesById(Set<Id> casesIds) {
        return [
            SELECT Id, Request_Type__c, Client_Type__c,    
                    Delivery_Method__c, Flood_Zone__c, Project_Address__c, Lot_Number__c,
                    Property_Owner__c, Receive_Date__c, SuppliedEmail, SuppliedPhone,
                    SuppliedCompany, SuppliedName, Priority, Project_Description__c,
                    Project_Name__c
            FROM Case 
            WHERE Id IN :casesIds
        ];
    }

    public Case getCaseById(Id caseId) {
        List<Case> cases = this.getCasesById(new Set<Id> { caseId });
        return cases.isEmpty() ? null : cases[0];
    }

    public List<Case> getCasesById(Set<Id> casesIds, Set<String> queryFields) {
        system.debug(String.join(queryFields, ','));
        return (List<Case>) Database.query(
            ' SELECT ' + String.join(queryFields, ',') +
            ' FROM Case' +
            ' WHERE Id IN :casesIds'
        );
    }

    public Case getCaseById(Id caseId, Set<String> queryFields) {
        List<Case> cases = this.getCasesById(new Set<Id> { caseId }, queryFields);
        return cases.isEmpty() ? null : cases[0];
    }
}