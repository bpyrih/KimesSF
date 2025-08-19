import { LightningElement, api, track, wire } from 'lwc';
import getQueues from '@salesforce/apex/AssignOpportunityQueueController.getQueues';
import assignQueueToOpportunity from '@salesforce/apex/AssignOpportunityQueueController.assignQueueToOpportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AssignOpportunityQueue extends LightningElement {
    @api recordId;
    @track queueOptions = [];
    @track selectedQueueId;

    @wire(getQueues)
    wiredQueues({ data, error }) {
        if (data) {
            this.queueOptions = data.map(q => ({ label: q.Name, value: q.Id }));
        } else if (error) {
            this.showToast('Error', 'Failed to load queues', 'error');
        }
    }

    handleChange(event) {
        this.selectedQueueId = event.detail.value;
    }

    handleSave() {
        if (!this.selectedQueueId) {
            this.showToast('Warning', 'Please select a queue', 'warning');
            return;
        }

        assignQueueToOpportunity({ opportunityId: this.recordId, queueId: this.selectedQueueId })
            .then(() => {
                this.showToast('Success', 'Queue assigned successfully', 'success');
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'An error occurred', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}