import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import downloadWorkFiles from '@salesforce/apex/WorkFileRelatedListController.downloadWorkFiles';
import annotateWorkFile from '@salesforce/apex/PDFRestService.annotateWorkFile';
import JSZipResource from '@salesforce/resourceUrl/JSZip';

import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DownloadWorkFiles extends LightningModal  {
    @api workFileData;
    @api opportunityId;
    _workFileData;

    isDownloadReady = false;
    downloadHref;
    zipName;

    get disableDownload() {
        return !this.isDownloadReady;
    }

    async connectedCallback() {
        this._workFileData = JSON.parse(JSON.stringify(this.workFileData));
        try {
            await loadScript(this, JSZipResource);
            this.zipInitialized = true;
        } catch(error) {
            console.error(error);
        }

        try {
            let data = await downloadWorkFiles({ opportunityId : this.opportunityId, workFileInfos: await this.getWorkFilesForReadyForSign() })
            if (!data.files.length) {
                this.handleInfo('No files to download.');
                this.close('No Files');
                return;
            }
        
            const zip = new window.JSZip();
            const folder = zip.folder(data.opportunityName + " Work files for Sign");
            data.files.forEach(f => folder.file(f.fileName, f.fileContent, { base64: true }));
            
            let blob = await zip.generateAsync({ type: 'blob' });

            this.downloadHref = URL.createObjectURL(blob);
            this.zipName = `${data.opportunityName + " Work files for Sign"}.zip`;
            this.isDownloadReady = true;
            
            this.handleSuccess('Zip is generated!');
        } catch (error) {
            this.handleError('Error during zip generation. ' + error.message);
            console.error(error);
        }
    }

    async getWorkFilesForReadyForSign() {
        const annotatedWorkFiles = [];
        for (let i = 0; i < this._workFileData.length; i++) {
            let workFile = this._workFileData[i];
            console.log(workFile.workFileStatus);
            
            if (workFile.workFileStatus === 'Annotated') {
                annotatedWorkFiles.push(workFile);
            } else if (workFile.workFileStatus === 'Draft') {
                try {
                    const annotatedVersionId = await annotateWorkFile({workFileId : workFile.workFileId});
                    console.log(annotatedVersionId);
                    workFile.versionId = annotatedVersionId;
                    
                    if (annotatedVersionId) {
                        annotatedWorkFiles.push(workFile);
                    }
                } catch (error) {
                    console.error(error);
                    console.error(error.message);
                }
            }
        }
        return annotatedWorkFiles;
    }

    handleDownload() {
        this.refs.documentZip.click();
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