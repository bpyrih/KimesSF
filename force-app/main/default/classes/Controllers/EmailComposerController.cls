public with sharing class EmailComposerController {
    
    public class TemplateDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public String subject;
        @AuraEnabled public String body;
    }
    
    public class FileRowDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public Decimal sizeKB;
        @AuraEnabled public String lastModified;
    }
    
    public class InitialDataDTO {
        @AuraEnabled public String defaultTo;
        @AuraEnabled public String defaultSubject;
        @AuraEnabled public String defaultBody;
        @AuraEnabled public List<FileRowDTO> workFiles;
        @AuraEnabled public List<FileRowDTO> quoteFiles;
        @AuraEnabled public List<TemplateDTO> templates;
    }
    
    @AuraEnabled(cacheable=true)
    public static InitialDataDTO getInitialData(Id caseId) {
        if (caseId == null) throw new AuraHandledException('caseId is required');
        
        Case c = [SELECT Id, Subject, SuppliedEmail, Opportunity__c, ContactId, AccountId
              FROM Case WHERE Id = :caseId LIMIT 1];
        
        InitialDataDTO dto = new InitialDataDTO();
        dto.defaultTo = c.SuppliedEmail;
        dto.defaultSubject = 'Re: ' + (String.isBlank(c.Subject) ? 'Case ' + c.Id : c.Subject);
        dto.defaultBody = '<p>Hello,</p><p></p><p>Best regards,</p>';
        
        Set<Id> workFileIds = new Map<Id, Work_File__c>(
            [SELECT Id FROM Work_File__c WHERE Opportunity__c = :c.Opportunity__c]
            ).keySet();
        
        Set<Id> quoteIds = new Map<Id, Quote>(
            [SELECT Id FROM Quote WHERE OpportunityId = :c.Opportunity__c]
            ).keySet();
        
        dto.workFiles = fetchWorkFileRows(workFileIds);
        dto.quoteFiles = fetchQuoteFileRows(quoteIds);
        
        dto.templates = fetchTemplates(c);
        
        return dto;
    }
    
    private static Set<Id> getWorkFileIds(Id oppId) {
        if (oppId == null) return new Set<Id>();
        return new Map<Id, Work_File__c>(
            [SELECT Id FROM Work_File__c WHERE Opportunity__c = :oppId]
            ).keySet();
    }
    
    private static Set<Id> getQuoteIds(Id oppId) {
        if (oppId == null) return new Set<Id>();
        return new Map<Id, Quote>(
            [SELECT Id FROM Quote WHERE OpportunityId = :oppId]
            ).keySet();
    }
    
    private static List<FileRowDTO> fetchWorkFileRows(Set<Id> workFileIds) {
        if (workFileIds.isEmpty()) return new List<FileRowDTO>();
        List<ContentDocumentLink> links = [
        SELECT ContentDocumentId, LinkedEntityId 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId IN :workFileIds
    ];
        
        if (links.isEmpty()) return new List<FileRowDTO>();
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink l : links) docIds.add(l.ContentDocumentId);
        
        Map<Id, ContentVersion> latestSignedMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
        SELECT Id, ContentDocumentId, Title, FileType, ContentSize, LastModifiedDate, Is_Latest_Signed__c
        FROM ContentVersion
        WHERE ContentDocumentId IN :docIds
        ORDER BY LastModifiedDate DESC
    ]) {
            if (cv.Is_Latest_Signed__c && !latestSignedMap.containsKey(cv.ContentDocumentId)) {
                latestSignedMap.put(cv.ContentDocumentId, cv);
            }
        }
        
        return buildFileRowDTOs(links, latestSignedMap);
    }
    
    private static List<FileRowDTO> fetchQuoteFileRows(Set<Id> quoteIds) {
        if (quoteIds.isEmpty()) return new List<FileRowDTO>();
        List<ContentDocumentLink> links = [
        SELECT ContentDocumentId, LinkedEntityId 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId IN :quoteIds
    ];
        
        if (links.isEmpty()) return new List<FileRowDTO>();
        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink l : links) docIds.add(l.ContentDocumentId);
        
        Map<Id, ContentVersion> latestMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
        SELECT Id, ContentDocumentId, Title, FileType, ContentSize, LastModifiedDate
        FROM ContentVersion
        WHERE ContentDocumentId IN :docIds
        ORDER BY LastModifiedDate DESC
    ]) {
            if (!latestMap.containsKey(cv.ContentDocumentId)) {
                latestMap.put(cv.ContentDocumentId, cv);
            }
        }
        
        return buildFileRowDTOs(links, latestMap);
    }
    
    private static List<FileRowDTO> buildFileRowDTOs(List<ContentDocumentLink> links, Map<Id, ContentVersion> versionsMap) {
        List<FileRowDTO> rows = new List<FileRowDTO>();
        Set<Id> addedDocs = new Set<Id>();
        
        for (ContentDocumentLink l : links) {
            if (addedDocs.contains(l.ContentDocumentId)) continue;
            ContentVersion v = versionsMap.get(l.ContentDocumentId);
            if (v == null) continue;
            
            FileRowDTO r = new FileRowDTO();
            r.id = l.ContentDocumentId;
            
            String fileName = v.Title;
            if (!fileName.toLowerCase().endsWith('.' + v.FileType.toLowerCase())) {
                fileName += '.' + v.FileType;
            }
            r.title = fileName;
            r.fileType = v.FileType;
            r.sizeKB = v.ContentSize != null ? (Decimal.valueOf(v.ContentSize) / 1024).setScale(1) : null;
            r.lastModified = v.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            
            rows.add(r);
            addedDocs.add(l.ContentDocumentId);
        }
        
        return rows;
    }
    private static List<TemplateDTO> fetchTemplates(Case c) {
        List<TemplateDTO> out = new List<TemplateDTO>();
        List<EmailTemplate> templates = [
        SELECT Id, Name, Subject, HtmlValue, Body
        FROM EmailTemplate 
        WHERE IsActive = true AND (folder.Name  =  'Case reply with file templates')
        LIMIT 50
    ];
        
        if (templates.isEmpty()) {
            System.debug('No active templates found in folder "Case Templates".');
            return out;
        }
        for (EmailTemplate et : templates) {
            try {
                Messaging.SingleEmailMessage rendered = Messaging.renderStoredEmailTemplate(
                    et.Id,
                c.ContactId,
                c.Id
                    );
                
                TemplateDTO t = new TemplateDTO();
                t.id = et.Id;
                t.label = et.Name;
                
                String htmlBody = rendered.getHtmlBody();
                String plainTextBody = rendered.getPlainTextBody();
                t.body = !String.isBlank(htmlBody) ? htmlBody : plainTextBody;
                
                out.add(t);
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Could not render template "' + et.Name + '" (' + et.Id + '). Error: ' + e.getMessage());
            }
        }
        
        return out;
    }
    
    
    @AuraEnabled
    public static void sendEmail(
        Id caseId,
    String toAddressesCsv,
    String ccAddressesCsv,
    String bccAddressesCsv,
    String htmlBody,
    List<Id> contentDocumentIds
    ) {
        if(caseId == null) throw new AuraHandledException('caseId is required');
        if(String.isBlank(toAddressesCsv)) throw new AuraHandledException('To address is required');
        if(String.isBlank(htmlBody)) throw new AuraHandledException('Body is required');
        
        try {
            Messaging.SingleEmailMessage mail = buildEmailMessage(
                caseId, toAddressesCsv, ccAddressesCsv, bccAddressesCsv, htmlBody, contentDocumentIds
                );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        } catch(Exception e) {
            throw new AuraHandledException('Failed to send email: ' + e.getMessage());
        }
    }
    
    private static Messaging.SingleEmailMessage buildEmailMessage(
        Id caseId,
    String toAddressesCsv,
    String ccAddressesCsv,
    String bccAddressesCsv,
    String htmlBody,
    List<Id> contentDocumentIds
    ) {
        Case relatedCase = [
        SELECT Id, CaseNumber, Subject,
            (SELECT Id, MessageIdentifier, ToAddress 
             FROM Emails ORDER BY CreatedDate ASC LIMIT 1)
        FROM Case
        WHERE Id = :caseId
        LIMIT 1
    ];
        
        String inboundAddress = '';
        String originalMessageId = '';
        if(!relatedCase.Emails.isEmpty()){
            EmailMessage firstEmail = relatedCase.Emails[0];
            inboundAddress = firstEmail.ToAddress;
            originalMessageId = firstEmail.MessageIdentifier;
        }
        
        String threadingToken = EmailMessages.getFormattedThreadingToken(caseId);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(splitCsv(toAddressesCsv));
        mail.setCcAddresses(splitCsv(ccAddressesCsv));
        mail.setBccAddresses(splitCsv(bccAddressesCsv));
        
        if (!String.isBlank(inboundAddress)) {
            OrgWideEmailAddress[] owea = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = :inboundAddress LIMIT 1
        ];
            if (!owea.isEmpty()) {
                mail.setOrgWideEmailAddressId(owea[0].Id);
            }
        }
        
        if(!String.isBlank(originalMessageId)) {
            mail.setInReplyTo(originalMessageId);
            mail.setReferences(originalMessageId);
        }
        
        mail.setSubject('RE: ' + relatedCase.Subject);
        mail.setHtmlBody(htmlBody + '<br><br>Ref: ' + relatedCase.CaseNumber + '<br><br>' + threadingToken);
        mail.setWhatId(relatedCase.Id);
        mail.setSaveAsActivity(true);
        
        List<Messaging.EmailFileAttachment> attachments = buildAttachments(contentDocumentIds);
        if(!attachments.isEmpty()) {
            mail.setFileAttachments(attachments);
        }
        
        return mail;
    }
    
    private static List<Messaging.EmailFileAttachment> buildAttachments(List<Id> contentDocumentIds) {
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        if(contentDocumentIds == null || contentDocumentIds.isEmpty()) return attachments;
        
        Set<Id> addedDocs = new Set<Id>();
        
        for(ContentDocumentLink cdl : [
        SELECT ContentDocument.LatestPublishedVersionId 
        FROM ContentDocumentLink 
        WHERE ContentDocumentId IN :contentDocumentIds
    ]) {
            if(addedDocs.contains(cdl.ContentDocument.LatestPublishedVersionId)) continue;
            
            ContentVersion cv = [
            SELECT VersionData, Title, FileExtension 
            FROM ContentVersion 
            WHERE Id = :cdl.ContentDocument.LatestPublishedVersionId 
            LIMIT 1
        ];
            
            String fileName = cv.Title;
            if(!fileName.toLowerCase().endsWith('.' + cv.FileExtension.toLowerCase())) {
                fileName += '.' + cv.FileExtension;
            }
            
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(fileName);
            efa.setBody(cv.VersionData);
            attachments.add(efa);
            
            addedDocs.add(cdl.ContentDocument.LatestPublishedVersionId);
        }
        return attachments;
    }
    
    
    private static List<String> splitCsv(String csv){
        List<String> out = new List<String>();
        if(!String.isBlank(csv)){
            for(String s : csv.split('[;:,]')){
                if(!String.isBlank(s)) out.add(s.trim());
            }
        }
        return out;
    }
}