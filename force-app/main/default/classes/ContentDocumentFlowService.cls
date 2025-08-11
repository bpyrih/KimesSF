public with sharing class ContentDocumentFlowService {
    public class Request {
        @InvocableVariable(label='Source ContentDocument Id' required=true)
        public Id sourceContentDocumentId;
        @InvocableVariable(label='Target Parent Id' required=true)
        public Id targetParentId;
        @InvocableVariable(label='Title' required=false)
        public String title;
        @InvocableVariable(label='Description' required=false)
        public String description;
        @InvocableVariable(label='New Version Reason' required=false)
        public String reason;
    }
    public class Response {
        @InvocableVariable(label='New ContentDocument Id')
        public Id newContentDocumentId;
    }

    @InvocableMethod(label='Bulk Clone ContentDocuments')
    public static List<Response> cloneDocs(List<Request> requests) {
        System.debug(requests);
        // 1. Prepare ordered lists of inputs
        List<Id> sourceDocIds = new List<Id>();
        List<Id> targetParentIds = new List<Id>();
        List<String> descriptions = new List<String>();
        List<String> titles = new List<String>();
        List<String> reasons = new List<String>();
        for (Request r : requests) {
            sourceDocIds.add(r.sourceContentDocumentId);
            targetParentIds.add(r.targetParentId);
            descriptions.add(r.description);
            titles.add(r.title);
            reasons.add(r.reason);
        }

        // 2. Fetch latest versions in same order as sourceDocIds
        Map<Id, ContentVersion> latestMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Title, VersionData, PathOnClient, FileType, Description
            FROM ContentVersion
            WHERE ContentDocumentId IN :sourceDocIds AND IsLatest = true
        ]) {
            latestMap.put(cv.ContentDocumentId, cv);
        }

        // 3. Clone in parallel
        List<ContentVersion> clones = new List<ContentVersion>();
        for (Id srcId : sourceDocIds) {
            ContentVersion sv = latestMap.get(srcId);
            if (sv != null) {
                ContentVersion clone = sv.clone(false, true, false, false);
                clone.ContentDocumentId = null;
                clone.ContentBodyId = null;
                clone.Title = titles.get(sourceDocIds.indexOf(srcId));
                clone.PathOnClient = titles.get(sourceDocIds.indexOf(srcId)) + '.pdf';
                clone.Description = descriptions.get(sourceDocIds.indexOf(srcId));
                clone.ReasonForChange = reasons.get(sourceDocIds.indexOf(srcId));
                clones.add(clone);
            } else {
                clones.add(null); // keep structure
            }
        }
        // Remove nulls before insert
        List<ContentVersion> validClones = new List<ContentVersion>();
        for (ContentVersion cv : clones) {
            if (cv != null) validClones.add(cv);
        }
        insert validClones;

        // 4. Re-query inserted clones to get ContentDocumentId
        clones = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :validClones
            ORDER BY CreatedDate // ensures consistent order
        ];

        // 5. Build links/responses using aligned indexes
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        List<Response> results = new List<Response>();
        Integer cloneIdx = 0;

        for (Integer i = 0; i < sourceDocIds.size(); i++) {
            if (clones.size() <= cloneIdx) break;
            ContentVersion cv = clones[cloneIdx];
            cloneIdx++;
            Id newDocId = cv.ContentDocumentId;
            Id parentId = targetParentIds[i];

            links.add(new ContentDocumentLink(
                ContentDocumentId = newDocId,
                LinkedEntityId = parentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
            Response r = new Response();
            r.newContentDocumentId = newDocId;
            results.add(r);
        }

        insert links;
        return results;
    }
}