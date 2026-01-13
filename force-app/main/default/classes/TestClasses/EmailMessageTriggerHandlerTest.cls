@isTest
public with sharing class EmailMessageTriggerHandlerTest {
    // Helper method to build an EmailMessage record
    private static EmailMessage createEmailMessage(Id caseId, Boolean isIncoming, String fromAddr, String toAddr, String subj) {
        EmailMessage em = new EmailMessage();
        em.ParentId = caseId;
        em.Incoming = isIncoming;
        em.FromAddress = fromAddr;
        em.ToAddress = toAddr;
        em.Subject = subj;
        em.HtmlBody = 'Test body';
        return em;
    }
    
    @isTest static void testReopenClosedCase() {

        Case closedCase = new Case(Status = 'Closed', Origin = 'Email', Subject = 'Closed Case');
        insert closedCase;

        EmailMessage inboundEmail = createEmailMessage(closedCase.Id, true, 
                                'testagent@address.com', 'testclient@address.com', 'Reopen Request');
        insert inboundEmail;

        Case updatedCase = [SELECT Status, LastModifiedDate FROM Case WHERE Id = :closedCase.Id];
        System.assertEquals('Client Replied', updatedCase.Status, 'Closed case should be reopened to New on customer email');
    }
    
    @isTest static void testCustomerReplyOnOpenCase() {

        Case openCase = new Case(Status = 'Working', Origin = 'Email', Subject = 'Open Case');
        insert openCase;

        EmailMessage replyEmail = createEmailMessage(openCase.Id, true, 
                                'testagent@address.com', 'testclient@address.com', 'Customer follow-up');
        insert replyEmail;

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :openCase.Id];
        System.assertEquals('Client Replied', updatedCase.Status, 
            'Open case should be marked as Customer Replied when customer sends a reply');
    }
    
    @isTest static void testInboundEmailOnNewCase() {

        Case newCase = new Case(Status = 'New', Origin = 'Email', Subject = 'New Case');
        insert newCase;

        EmailMessage additionalEmail = createEmailMessage(newCase.Id, true, 
                                  'testagent@address.com', 'testclient@address.com', 'Additional Info');
        insert additionalEmail;

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :newCase.Id];
        System.assertEquals('Client Replied', updatedCase.Status, 
            'Case already New should remain New on additional customer email');
    }
    
    @isTest static void testOutboundEmailNoStatusChange() {

        Case caseRecord = new Case(Status = 'Working', Origin = 'Email', Subject = 'Outbound Email Case');
        insert caseRecord;

        EmailMessage outboundEmail = createEmailMessage(caseRecord.Id, false, 
                                   'testagent@address.com', 'testclient@address.com', 'Agent Response');
        insert outboundEmail;

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('Agent Replied/Follow Up', updatedCase.Status, 
            'Outbound emails should not change the case status');
    }
    
    @isTest static void testBulkEmailProcessing() {

        Case case1 = new Case(Status = 'Working', Origin = 'Email', Subject = 'Bulk Case 1');
        Case case2 = new Case(Status = 'Closed', Origin = 'Email', Subject = 'Bulk Case 2');
        Case case3 = new Case(Status = 'New', Origin = 'Email', Subject = 'Bulk Case 3');
        insert new List<Case>{ case1, case2, case3 };

        List<EmailMessage> emailsToInsert = new List<EmailMessage>();

        emailsToInsert.add(createEmailMessage(case1.Id, true, 
                           'testagent@address.com', 'testclient@address.com', 'Bulk Email 1'));

        emailsToInsert.add(createEmailMessage(case2.Id, true, 
                           'testagent@address.com', 'testclient@address.com', 'Bulk Email 2'));

        emailsToInsert.add(createEmailMessage(case3.Id, false, 
                           'testagent@address.com', 'testclient@address.com', 'Bulk Email 3'));
        insert emailsToInsert;

        Case result1 = [SELECT Status FROM Case WHERE Id = :case1.Id];
        Case result2 = [SELECT Status FROM Case WHERE Id = :case2.Id];
        Case result3 = [SELECT Status FROM Case WHERE Id = :case3.Id];
        System.assertEquals('Client Replied', result1.Status, 'Case1 should be Client Replied');
        System.assertEquals('Client Replied', result2.Status, 'Case2 (closed) should be reopened to New');
        System.assertEquals('Agent Replied/Follow Up', result3.Status, 'Case3 was New and had only outbound email, so should remain New');
    }
}