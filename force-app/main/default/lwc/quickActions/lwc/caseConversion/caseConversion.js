import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import convertCaseToLead from "@salesforce/apex/ConversionController.convertCaseToLead";

const SUCCESS_MESSAGE = 'Case converted to lead successfully!';
const ERROR_MESSAGE = 'Case could not be converted to lead. Web Email/Name/Company fields are required!';

export default class CaseConversion extends NavigationMixin(LightningElement) {
    @api
    recordId;

    conversionStarted = false;

    renderedCallback() {
        if (this.recordId && !this.conversionStarted) {
            this.conversionStarted = true;
            this.convertCase();
        }   
    }

    convertCase() {
        convertCaseToLead({caseId: this.recordId})
        .then((leadId) => {
            this.showSuccess(SUCCESS_MESSAGE);
            this.navigateToConvertedLead(leadId);
        })
        .catch((error) => {
            console.log(error);
            this.showError(ERROR_MESSAGE);
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    navigateToConvertedLead(leadId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                actionName: 'view'
            }
        });
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