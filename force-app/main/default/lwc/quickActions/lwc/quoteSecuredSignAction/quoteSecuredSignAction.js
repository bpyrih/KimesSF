import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import uploadAndSendQuotePdf from '@salesforce/apex/SecuredSignFacade.uploadAndSendQuotePdf';

export default class QuoteSendToSign extends LightningElement {
    @api recordId;
    isLoading = false;
    message = 'Send the current quote PDF to the contact for e-signature.';
    isSuccess = false;

    async handleSend() {
        if (!this.recordId) {
            this._toast('Quote is missing', 'No Quote Id on context.', 'error');
            this.message = 'Quote Id is missing.';
            return;
        }

        this.isLoading = true;
        this.isSuccess = false;

        try {
            await uploadAndSendQuotePdf({ quoteId: this.recordId });
            this.isSuccess = true;
            this.message = 'Document was sent to the quote contact for e-signature.';
            this._toast('Sent', 'Email invitation was sent to the quote contact.', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (e) {
            const msg =
                (e && e.body && e.body.message) ||
                (e && e.message) ||
                'Failed to send quote.';
            this.message = msg;
            this._toast('Error', msg, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get messageClass() {
        return this.isSuccess ? 'muted success' : 'muted';
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
