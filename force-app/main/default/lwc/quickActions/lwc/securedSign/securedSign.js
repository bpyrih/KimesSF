import { LightningElement, api, track } from 'lwc';
import uploadAndSignWorkFile from '@salesforce/apex/SecuredSignFacade.uploadAndSignWorkFile';

export default class UploadSign extends LightningElement {
    @api recordId;
    @api documentRef = '';
    @api signingKey = ''; 

    @track email = '';
    @track firstName = '';
    @track lastName = '';
    @track isLoading = false;

    callbackUrl = 'https://kimes24--qa--c.sandbox.vf.force.com/apex/SecuredSignWeSignHost';

    handleInputChange(e) {
        const field = e.target.dataset.field;
        if (field) this[field] = e.target.value?.trim();
    }

    async handleUploadAndSign() {
        this._refreshInputs();
        if (!this._formValid()) {
            alert('Fill in first name, last name and email.');
            return;
        }

        this.isLoading = true;
        try {
            // Цей блок залишається без змін
            if (!this.documentRef) {
                if (!this.recordId) throw new Error('No recordId.');

                const res = await uploadAndSignWorkFile({
                    workFileId: this.recordId,
                    email: this.email,
                    firstName: this.firstName,
                    lastName: this.lastName,
                    x: 100, y: 100, width: 200, height: 50
                });

                this.documentRef = res?.documentRef || '';
                //this.signingKey = res?.signingKey || '';

                if (!this.documentRef) throw new Error('DocumentReference empty');
            }
            

            this._openSigningWindow();

        } catch (e) {
            console.error('❌ Upload/prepare error:', e);
            alert('Error during upload/prepare: ' + e.message);
        } finally {
            this.isLoading = false;
        }
    }

    handleSignExisting() {
        this._refreshInputs();
        if (!this._formValid()) {
            alert('Fill in first name, last name and email.');
            return;
        }
        if (!this.documentRef) {
            alert('No document to sign. Please upload a file first.');
            return;
        }
        

        this._openSigningWindow();
    }


    _openSigningWindow() {
        const params = new URLSearchParams({
            docRef: this.documentRef,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            signingKey: this.signingKey
        });

        const authUrl = `${this.callbackUrl}?${params.toString()}`;

        console.log('🔗 Opening VF page:', authUrl);
        window.open(authUrl, '_blank');
    }

    _refreshInputs() {
        this.firstName = this.template.querySelector('[data-field="firstName"]').value?.trim();
        this.lastName = this.template.querySelector('[data-field="lastName"]').value?.trim();
        this.email = this.template.querySelector('[data-field="email"]').value?.trim();
    }

    _formValid() {
        return Boolean(this.firstName && this.lastName && this.email);
    }
}