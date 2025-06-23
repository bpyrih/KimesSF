import { LightningElement, api, wire, track } from 'lwc';
import getRelatedWorkFiles from '@salesforce/apex/WorkFileRelatedListController.getRelatedWorkFiles';
import downloadCaseFiles from '@salesforce/apex/WorkFileRelatedListController.downloadCaseFiles';
import JSZipResource from '@salesforce/resourceUrl/JSZip';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WorkFileRelatedList extends LightningElement {
  @api recordId;
  @track files = [];
  @track error;
  zipInitialized = false;
  attachementRetrieved = false;

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

  connectedCallback() {
    if (!this.zipInitialized) {
       loadScript(this, JSZipResource)
       .then(() => { this.zipInitialized = true;})
       .catch(() => {this.handleError('Error loading JSZip'); console.log('asdasdasdsad');
       });
    } else {
       this.createZip();
    }
 }

  get isActionsDisabled() {
    console.log('isActionsDisabled reorder');
    
    console.log(!this.zipInitialized);
    console.log(!this.attachementRetrieved);
    
    return !this.zipInitialized || !this.attachementRetrieved;
  }

  @wire(getRelatedWorkFiles, { opportunityId: '$recordId' })
  wiredFiles({ error, data }) {
    if (data) {
      this.error = undefined;
      this.files = data.map(f => ({
        ...f,
        detailUrl: `/lightning/r/ContentDocument/${f.contentDocumentId}/view`
      }));
      this.attachementRetrieved = true;
    } else if (error) {
      this.files = [];
      this.error = 'Error loading files: ' +
        (error.body ? error.body.message : JSON.stringify(error));
    }
  }


  handleGetAllFiles() {
    downloadCaseFiles({ caseId: this.recordId })
    .then(data => {
       if (!data.files.length) return this.handleInfo('No files to download.');

       const zip = new window.JSZip();
       const folder = zip.folder(data.caseNumber + " Work files for Sign");
       data.files.forEach(f => folder.file(f.fileName, f.fileContent, { base64: true }));

       zip.generateAsync({ type: 'blob' })
       .then(blob => {
          const a = document.createElement('a');
          a.href = URL.createObjectURL(blob);
          a.download = `${data.caseNumber + " Work files for Sign"}.zip`;
          document.body.appendChild(a); a.click();
          a.remove();
          this.handleSuccess('Download successful');
       })
       .catch(() => this.handleError('Error creating ZIP'));
    })
    .catch(() => this.handleError('Error during download'));
  }

  handleSuccess(msg) {
    this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: msg, variant: 'success' }));
 }

 handleInfo(msg) {
    this.dispatchEvent(new ShowToastEvent({ title: 'Info', message: msg, variant: 'info' }));
 }

 handleError(msg) {
    this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
 }
}