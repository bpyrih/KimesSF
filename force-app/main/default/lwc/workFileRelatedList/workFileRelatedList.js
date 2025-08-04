import { LightningElement, api, wire, track } from 'lwc';
import getRelatedWorkFiles from '@salesforce/apex/WorkFileRelatedListController.getRelatedWorkFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import downloadWorkFilesModal from 'c/downloadWorkFiles';
import uploadWorkFilesModal from 'c/uploadWorkFiles';

const workFileColumsn = [
  {
    label: 'File Name',
    fieldName: 'detailUrl',
    type: 'url',
    typeAttributes: {
      label: { fieldName: 'fileName' },
      target: '_blank'
    }
  },
  { label: 'Work File Status', fieldName: 'workFileStatus', type: 'text' },
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

export default class WorkFileRelatedList extends LightningElement {
  @api recordId;
  @track files = [];
  @track error;

  workFilesDataWire;

  workFileData;

  columns = workFileColumsn;

  connectedCallback() {
 
 }

  @wire(getRelatedWorkFiles, { opportunityId: '$recordId' })
  wiredFiles(wireResult) {
    this.workFilesDataWire = wireResult;

    const {data, error} = wireResult;

    if (data) {
      this.error = undefined;
      this.workFileData = data;
      this.files = this.workFileData.map(f => ({
        ...f,
        detailUrl: `/lightning/r/ContentDocument/${f.contentDocumentId}/view`
      }));
    } else if (error) {
      this.files = [];
      this.error = 'Error loading files: ' +
        (error.body ? error.body.message : JSON.stringify(error));
    }
  }

  async handleMenuSelect(event) {
    const selectedItemValue = event.detail.value;
    if (selectedItemValue == 'item1') {
      await this.createDownloadWorkFilesModal();
    } else if (selectedItemValue == 'item2') {
      await this.createUploadWorkFilesModal();
    }
  }

  async createDownloadWorkFilesModal() {
    const result = await downloadWorkFilesModal.open({
      size: 'large',
      description: 'Create Zip Work Files package',
      workFileData: this.files,
      opportunityId: this.recordId,
    });
    this.handleRefresh();
    console.log(result);
  }

  async createUploadWorkFilesModal() {
    const result = await uploadWorkFilesModal.open({
      size: 'large',
      description: 'Upload Work Files',
      opportunityId: this.recordId,
    });
    if (result == 'Files Uploaded') {
      this.handleRefresh();
    }
    console.log(result);
  }

  async handleRefresh() {
    await refreshApex(this.workFilesDataWire);
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