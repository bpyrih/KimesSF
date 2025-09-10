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
        if(caseId == null) throw new AuraHandledException('caseId is required');
        
        Case c = [SELECT Id, Subject, SuppliedEmail, Opportunity__c, ContactId, AccountId 
                  FROM Case WHERE Id = :caseId LIMIT 1];
        
        InitialDataDTO dto = new InitialDataDTO();
        dto.defaultTo = c.SuppliedEmail;
        dto.defaultSubject = 'Re: ' + (String.isBlank(c.Subject) ? 'Case ' + c.Id : c.Subject);
        dto.defaultBody = '<p>Hello,</p><p></p><p>Best regards,</p>';
        
        dto.workFiles = fetchFilesByParents(getWorkFileIds(c.Opportunity__c));
        dto.quoteFiles = fetchFilesByParents(getQuoteIds(c.Opportunity__c));
        dto.templates = fetchTemplates(c);
        
        return dto;
    }
    
    private static Set<Id> getWorkFileIds(Id oppId) {
        if(oppId == null) return new Set<Id>();
        return new Map<Id, Work_File__c>(
            [SELECT Id FROM Work_File__c WHERE Opportunity__c = :oppId]
            ).keySet();
    }
    
    private static Set<Id> getQuoteIds(Id oppId) {
        if(oppId == null) return new Set<Id>();
        return new Map<Id, Quote>(
            [SELECT Id FROM Quote WHERE OpportunityId = :oppId]
            ).keySet();
    }
    
    private static List<FileRowDTO> fetchFilesByParents(Set<Id> parentIds) {
        if(parentIds.isEmpty()) return new List<FileRowDTO>();
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :parentIds
        ];
        
        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink l : links) docIds.add(l.ContentDocumentId);
        if(docIds.isEmpty()) return new List<FileRowDTO>();
        
        Map<Id, ContentVersion> latest = new Map<Id, ContentVersion>();
        for(ContentVersion cv : [
            SELECT Id, ContentDocumentId, Title, FileType, ContentSize, LastModifiedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds AND IsLatest = true
        ]) {
            latest.put(cv.ContentDocumentId, cv);
        }
        
        List<FileRowDTO> rows = new List<FileRowDTO>();
        Set<Id> addedDocs = new Set<Id>();
        
        for(ContentDocumentLink l : links) {
            if(addedDocs.contains(l.ContentDocumentId)) continue;
            ContentVersion v = latest.get(l.ContentDocumentId);
            if(v == null) continue;
            
            FileRowDTO r = new FileRowDTO();
            r.id = l.ContentDocumentId;
            
            String fileName = v.Title;
            if (!fileName.toLowerCase().endsWith('.' + v.FileType.toLowerCase())) {
                fileName += '.' + v.FileType;
            }
            r.title = fileName;
            
            r.fileType = v.FileType;
            r.sizeKB = v.ContentSize != null ? (Decimal.valueOf(v.ContentSize)/1024).setScale(1) : null;
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
        WHERE IsActive = true AND (Name LIKE '%Case%')
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
                t.subject = rendered.getSubject();
                
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
        
        Case relatedCase = [
            SELECT Id, CaseNumber,
                (SELECT Id, MessageIdentifier, Subject FROM Emails ORDER BY CreatedDate ASC LIMIT 1)
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        String originalMessageId = '';
        String originalSubject = 'RE: ' + relatedCase.CaseNumber;
        
        if(!relatedCase.Emails.isEmpty()){
            originalMessageId = relatedCase.Emails[0].MessageIdentifier;
            originalSubject = 'RE: ' + relatedCase.Emails[0].Subject;
        }
        
        String threadingToken = EmailMessages.getFormattedThreadingToken(caseId);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(splitCsv(toAddressesCsv));
        mail.setCcAddresses(splitCsv(ccAddressesCsv));
        mail.setBccAddresses(splitCsv(bccAddressesCsv));
        
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'torchdesigns@kimesengineering.com' LIMIT 1];
        if(!owea.isEmpty()) mail.setOrgWideEmailAddressId(owea[0].Id);
        
        if(originalMessageId != '') {
            mail.setInReplyTo(originalMessageId);
            mail.setReferences(originalMessageId);
        }
        
        mail.setSubject(originalSubject);
        mail.setHtmlBody(htmlBody + '<br><br>Ref: ' + relatedCase.CaseNumber + '<br><br>' + threadingToken);
        mail.setWhatId(relatedCase.Id);
        mail.setSaveAsActivity(true);
        
        if(contentDocumentIds != null && !contentDocumentIds.isEmpty()){
            Set<Id> addedDocs = new Set<Id>();
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            
            for(ContentDocumentLink cdl : [SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIds]){
                if(addedDocs.contains(cdl.ContentDocument.LatestPublishedVersionId)) continue;
                
                ContentVersion cv = [SELECT VersionData, Title, FileExtension FROM ContentVersion WHERE Id = :cdl.ContentDocument.LatestPublishedVersionId LIMIT 1];
                
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
            
            if(!attachments.isEmpty()) mail.setFileAttachments(attachments);
        }
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        } catch(Exception e) {
            throw new AuraHandledException('Failed to send email: ' + e.getMessage());
        }
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