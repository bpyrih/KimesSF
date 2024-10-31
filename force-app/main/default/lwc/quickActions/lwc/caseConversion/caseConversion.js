import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PPOJECT_ADDRESS_FORMULA_FIELD from "@salesforce/schema/Case.Project_Address_Formula__c";
import PPOJECT_ADDRESS_VALID_FIELD from "@salesforce/schema/Case.ProjectAddressValid__c";
import PROJECT_NAME_FIELD from "@salesforce/schema/Case.Project_Name__c";
import WEB_COMPANY_FORMULA_FIELD from "@salesforce/schema/Case.SuppliedCompany";
import WEB_NAME_FIELD from "@salesforce/schema/Case.SuppliedName";
import WEB_EMAIL_FIELD from "@salesforce/schema/Case.SuppliedEmail";

import convertCaseToLead from "@salesforce/apex/ConversionController.convertCaseToLead";

import { constantUtils } from 'c/lwcUtils';

const FIELDS = [
    PPOJECT_ADDRESS_FORMULA_FIELD, PROJECT_NAME_FIELD, 
    WEB_COMPANY_FORMULA_FIELD, WEB_NAME_FIELD, WEB_EMAIL_FIELD,
    PPOJECT_ADDRESS_VALID_FIELD
];

const WEB_FIELDS = [WEB_COMPANY_FORMULA_FIELD, WEB_NAME_FIELD, WEB_EMAIL_FIELD];

const FIELDS_LABELS = {
    SuppliedCompany : 'Web Company',
    SuppliedName : 'Web Name',
    SuppliedEmail : 'Web Email'
};

export default class CaseConversion extends NavigationMixin(LightningElement) {
    @api
    recordId;

    conversionStarted = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
    wiredRecord({ error, data }) {
        if (error) {
            console.log(error);
            this.showError(constantUtils.CASE_CONVERSION_MESSAGES.FATAL_ERROR_MESSAGE);
            this.dispatchEvent(new CloseActionScreenEvent());
        } else if (data) {
            if (!getFieldValue(data, PPOJECT_ADDRESS_VALID_FIELD) && getFieldValue(data, PROJECT_NAME_FIELD) === null) {
                this.showError(constantUtils.CASE_CONVERSION_MESSAGES.PROJECT_DATA_MISSED_ERROR_MESSAGE);
                this.dispatchEvent(new CloseActionScreenEvent());
            } else if (WEB_FIELDS.find(field => getFieldValue(data, field) === null)) {
                const missedFieldsArr = [];
                WEB_FIELDS.filter(field => getFieldValue(data, field) === null).forEach(field => {missedFieldsArr.push(FIELDS_LABELS[field.fieldApiName])});
                this.showError(constantUtils.CASE_CONVERSION_MESSAGES.WEB_FIELDS_ERROR_MESSAGE.replace('{0}', '"' + missedFieldsArr.join('" , "') + '"'));
                this.dispatchEvent(new CloseActionScreenEvent());
            } else {
                this.convertCase();
            }
        }
    }

    renderedCallback() {
        // if (this.recordId && !this.conversionStarted) {
        //     this.conversionStarted = true;
        //     this.convertCase();
        // }   
    }

    convertCase() {
        convertCaseToLead({caseId: this.recordId})
        .then((leadId) => {
            this.showSuccess(constantUtils.CASE_CONVERSION_MESSAGES.SUCCESS_MESSAGE);
            this.navigateToConvertedLead(leadId);
        })
        .catch((error) => {
            console.log(error);
            this.showError(ERROR_MESSAGE);
            this.dispatchEvent(new CloseActionScreenEvent());
        });
    }

    navigateToConvertedLead(leadId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                actionName: 'view'
            }
        }).then((url) => {
            window.location.replace(url);
        });
    }

    showSuccess(message) {
        this.showToast(message, constantUtils.SUCCESS_LABEL.toLowerCase(), 'Success!');
    }

    showError(message) {
        this.showToast(message, constantUtils.ERROR_LABEL.toLowerCase(), 'Error!');
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