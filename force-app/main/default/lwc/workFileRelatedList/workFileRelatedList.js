import { LightningElement, api, wire, track } from 'lwc';
import getRelatedWorkFiles from '@salesforce/apex/WorkFileRelatedListController.getRelatedWorkFiles';

export default class WorkFileRelatedList extends LightningElement {
  @api recordId;
  @track files = [];
  @track error;

  columns = [
    {
      label: 'File Name',
      fieldName: 'detailUrl',
      type: 'url',
      typeAttributes: {
        label: { fieldName: 'fileName' },
        target: '_blank'
      }
    },
    // { label: 'Type',           fieldName: 'fileType',       type: 'text'   },
    // { label: 'Size (bytes)',    fieldName: 'fileSize',       type: 'number' },
    // { label: 'Version',         fieldName: 'versionNumber',  type: 'number' },
    // {
    //   label: 'Last Modified',
    //   fieldName: 'lastModified',
    //   type: 'date',
    //   typeAttributes: {
    //     year: 'numeric',
    //     month: 'short',
    //     day: '2-digit',
    //     hour: '2-digit',
    //     minute: '2-digit'
    //   }
    // }
  ];

  @wire(getRelatedWorkFiles, { opportunityId: '$recordId' })
  wiredFiles({ error, data }) {
    if (data) {
      this.error = undefined;
      this.files = data.map(f => ({
        ...f,
        detailUrl: `/lightning/r/ContentDocument/${f.contentDocumentId}/view`
      }));
    } else if (error) {
      this.files = [];
      this.error = 'Error loading files: ' +
        (error.body ? error.body.message : JSON.stringify(error));
    }
  }
}