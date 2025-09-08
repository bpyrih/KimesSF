import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getInitialData from '@salesforce/apex/EmailComposerController.getInitialData';
import sendEmail from '@salesforce/apex/EmailComposerController.sendEmail';

export default class CaseEmailComposer extends LightningElement {
    @api recordId;

    @track toInput = '';
    @track subject = '';
    @track body = '';

    @track workFiles = [];
    @track quoteFiles = [];

    @track templateOptions = [];
    @track selectedTemplateId;

    @track selectedWorkFileIds = [];
    @track selectedQuoteFileIds = [];

    @track sending = false;

    _templatesById = {};

    hideCheckbox = false;
    showRowNumbers = true;

    fileColumns = [
        { label: 'File Name', fieldName: 'title', type: 'text' },
        { label: 'Type', fieldName: 'fileType', type: 'text', initialWidth: 90 },
        { label: 'Size (KB)', fieldName: 'sizeKB', type: 'number', initialWidth: 110 },
        { label: 'Last Modified', fieldName: 'lastModified', type: 'date', initialWidth: 160 }
    ];

    get hasWorkFiles() {
        return this.workFiles.length > 0;
    }

    get hasQuoteFiles() {
        return this.quoteFiles.length > 0;
    }

    @wire(getInitialData, { caseId: '$recordId' })
    wiredInitial({ error, data }) {
        if (data) {
            this.toInput = data.defaultTo || '';
            this.subject = data.defaultSubject || '';
            this.body = data.defaultBody || '';

            // перетворюємо рядки дат у JS Date
            this.workFiles = (data.workFiles || []).map(f => ({
                ...f,
                lastModified: f.lastModified ? new Date(f.lastModified) : null
            }));

            this.quoteFiles = (data.quoteFiles || []).map(f => ({
                ...f,
                lastModified: f.lastModified ? new Date(f.lastModified) : null
            }));

            this.templateOptions = (data.templates || []).map(t => ({ label: t.label, value: t.id }));
            this._templatesById = {};
            (data.templates || []).forEach(t => { this._templatesById[t.id] = { body: t.body }; });
        } else if (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        }
    }

    handleSubjectChange(e) { this.subject = e.target.value; }
    handleBodyChange(e) { this.body = e.target.value; }

    handleTemplateSelect(e) {
        this.selectedTemplateId = e.detail.value;
        const template = this._templatesById[this.selectedTemplateId];
        if (template && template.body) {
            this.body = template.body;
        }
    }

    handleWorkFilesSelect(event) {
        this.selectedWorkFileIds = event.detail.selectedRows.map(r => r.id);
    }

    handleQuoteFilesSelect(event) {
        this.selectedQuoteFileIds = event.detail.selectedRows.map(r => r.id);
    }

    handleClear() {
        this.subject = '';
        this.body = '';
        this.selectedWorkFileIds = [];
        this.selectedQuoteFileIds = [];
        this.selectedTemplateId = null;
    }

    async handleSend() {
        if (!this.body) {
            this.showToast('Missing info', 'Message body is required.', 'warning');
            return;
        }
        this.sending = true;
        try {
            const attachments = [...this.selectedWorkFileIds, ...this.selectedQuoteFileIds];
            await sendEmail({
                caseId: this.recordId,
                toAddressesCsv: this.toInput,
                ccAddressesCsv: '',
                bccAddressesCsv: '',
                htmlBody: this.body,
                contentDocumentIds: attachments
            });
            this.showToast('Email sent', 'Your email was sent and logged to the Case.', 'success');
            this.dispatchEvent(new CustomEvent('emailsent'));
            this.handleClose();
        } catch (e) {
            this.showToast('Send failed', this.reduceError(e), 'error');
        } finally {
            this.sending = false;
        }
    }

    reduceError(error) {
        return (error?.body?.message || error?.message || 'Unknown error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
