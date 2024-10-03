import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import convertCaseToOpportunity from "@salesforce/apex/ConversionController.convertCaseToOpportunity";

const SUCCESS_MESSAGE = 'Case converted to Opportunity successfully!';
const ERROR_MESSAGE = 'Case could not be converted to Opportunity';

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
        convertCaseToOpportunity({caseId: this.recordId})
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