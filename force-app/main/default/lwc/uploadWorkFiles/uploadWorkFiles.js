import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import uploadWorkFiles from '@salesforce/apex/WorkFileRelatedListController.uploadWorkFiles';
import uploadWorkFile from '@salesforce/apex/WorkFileRelatedListController.uploadWorkFile';

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

        let files = Array.from(event.target.files).map(file => {
            return {
                name: file.name,
                base64: null,
                file
            };
        });
        files.forEach((f, index) => {
            const reader = new FileReader();
            reader.onload = () => {
                this.files[index].base64 = reader.result.split(',')[1];
                console.log(JSON.stringify(this.files));
            };
            reader.readAsDataURL(f.file);
        });

        this.files.push(...files);
    }

    handleUpload() {
        for (let i = 0; i < this.files.length; i++) {
            if (this.files[i].reason == null) {
                this.handleError('Please fill all Change Reason fields!');
                return;
            }
        }

        this.uploadStarted = true;
        const promises = [];

        this.files.forEach(f => {
            console.log(f.description);
            console.log(f.reason);
            
            promises.push(uploadWorkFile({ opportunityId: this.opportunityId, uploadFile: {fileName: f.name, fileReason: f.reason, fileDescription: f.description, isLatestSigned : false, fileContent: f.base64} }));
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

    handleChange(event) {
        console.log(event.target.value);
        console.log(event.target.label);
        console.log(event.target.dataset.key);
        
        let file = this.files.find(f => f.name === event.target.dataset.key);

        if (event.target.label == 'Description') {
            file.description = event.target.value;
        }
        else if (event.target.label == 'Change Reason') {
            file.reason = event.target.value;   
        }
    }

    handleClick(event) {
        console.log(event.target.dataset.key);
        
        let files = this.files.filter(f => f.name !== event.target.dataset.key);
        this.files = files;
    }
}