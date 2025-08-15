import { LightningElement, api, track, wire } from "lwc";
import getAssignableUsers from "@salesforce/apex/AssignOpportunityUserController.getAssignableUsers";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {CloseActionScreenEvent} from "lightning/actions";
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import assignOpportunityToUser from "@salesforce/apex/AssignOpportunityUserController.assignOpportunityToUser";

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
        assignOpportunityToUser({ opportunityId: this.recordId, userId: this.selectedUserId })
            .then(() => {
                this.showToast('Success', 'Opportunity assigned successfully', 'success');
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.closeModal();
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'An error occurred', 'error');
            });
    }

    handleCancel() {
        this.closeModal();
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}