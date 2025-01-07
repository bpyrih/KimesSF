import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import sentReview from "@salesforce/apex/WorkFileSignController.sentReview";

import ENGINEER_SIGN_USER from "@salesforce/schema/Work_File__c.Engineer_Sign_User__c";

const FIELDS = [
    ENGINEER_SIGN_USER
];

export default class SendDocumentReview extends NavigationMixin(LightningElement) {
    @api
    recordId;

    url;
    
    get loading() {
        return !this.recordId || !this.url;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
            this.showError(constantUtils.CASE_CONVERSION_MESSAGES.FATAL_ERROR_MESSAGE);
            this.dispatchEvent(new CloseActionScreenEvent());
        } else if (data) {
            if (!getFieldValue(data, ENGINEER_SIGN_USER)) {
                this.showError('Populate Engineer Sign User for Sign process!');
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                this.processSigning();
            }
        }
    }
    
    processSigning() {
        sentReview({workFileId : this.recordId})
        .then(result => {
            this.url = result;
        })
        .catch((error) => {
            console.log(error);
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    handleClick() {
        window.close();
    }

    showSuccess(message) {
        this.showToast(message, 'success', 'Success!');
    }

    showError(message) {
        this.showToast(message, 'error', 'Error!');
    }

    showToast(message, variant, title) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}