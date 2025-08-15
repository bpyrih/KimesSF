import { LightningElement, api, track, wire } from "lwc";
import getAssignableUsers from "@salesforce/apex/AssignOpportunityUserController.getAssignableUsers";
import assignUserToOpportunity from "@salesforce/apex/AssignOpportunityUserController.assignUserToOpportunity";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {CloseActionScreenEvent} from "lightning/actions";
import { getRecordNotifyChange } from "lightning/uiRecordApi";

export default class UserChange extends LightningElement {
    @api recordId;
    @track userOptions = [];
    @track selectedUserId;

    @wire(getAssignableUsers)
    wiredUsers({ data, error }) {
        if (data) {
            this.userOptions = data.map(user => ({ 
                label: user.Name, 
                value: user.Id 
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load users', 'error');
        }
    }

    handleChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handleSave() {
        if (!this.selectedUserId) {
            this.showToast('Warning', 'Please select a user', 'warning');
            return;
        }

        assignUserToOpportunity({ opportunityId: this.recordId, userId: this.selectedUserId })
            .then(() => {
                this.showToast('Success', 'User assigned successfully', 'success');
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'An error occurred', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant }));
    }
}