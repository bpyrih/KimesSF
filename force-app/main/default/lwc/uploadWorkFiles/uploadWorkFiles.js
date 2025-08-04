import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import uploadWorkFiles from '@salesforce/apex/WorkFileRelatedListController.uploadWorkFiles';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UploadWorkFiles extends LightningModal {
    @api opportunityId;

    @track files = [];

    uploadStarted = false;

    get disableUpload() {
        if (this.uploadStarted) {
            return true;
        }

        let allFilesLoaded = true;

        if (!this.files.length) {
            allFilesLoaded = false;
        }

        this.files.forEach((f, index) => {
            if (f.base64 == null) {
                allFilesLoaded = false;
            }
        });

        return !allFilesLoaded;
    }

    handleFiles(event) {
        for (let i = 0; i < event.target.files.length; i++) {
            if (event.target.files[i].type !== 'application/pdf') {
                this.handleError('Only PDF files are allowed!');
                return;
            }
        }

        this.files = Array.from(event.target.files).map(file => {
            return {
                name: file.name,
                base64: null,
                file
            };
        });
        this.files.forEach((f, index) => {
            const reader = new FileReader();
            reader.onload = () => {
                this.files[index].base64 = reader.result.split(',')[1];
                console.log(JSON.stringify(this.files));
            };
            reader.readAsDataURL(f.file);
        });
    }

    handleUpload() {
        this.uploadStarted = true;
        const promises = [];

        this.files.forEach(f => {
            promises.push(uploadWorkFiles({ opportunityId: this.opportunityId, uploadFiles: [{fileName: f.name, fileContent: f.base64}] }));
            // .then(result => {
            //     console.log('Upload result:', result);
            // })
            // .catch(err => {
            //     console.error(err);
            // });
        });
        Promise.all(promises).then((results) => {
            results.forEach((result) => console.log(result));
            this.handleSuccess('Files Uploaded');
            this.close('Files Uploaded');
        });
        console.log(JSON.stringify(payload));
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