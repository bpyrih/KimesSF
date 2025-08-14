import { LightningElement, api, track, wire } from 'lwc';
import getQueues from '@salesforce/apex/AssignOpportunityQueueController.getQueues';
import assignQueueToOpportunity from '@salesforce/apex/AssignOpportunityQueueController.assignQueueToOpportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class QueueSelector extends LightningElement {
    @api recordId;
    @track queueOptions = [];
    selectedQueueId;

    @wire(getQueues)
    wiredQueues({ error, data }) {
        if (data) {
            this.queueOptions = data.map(q => ({
                label: q.name,
                value: q.id
            }));
        } else if (error) {
            console.error(error);
        }
    }

    handleChange(event) {
        this.selectedQueueId = event.detail.value;
    }

    handleSave() {
        if (!this.selectedQueueId) {
            this.showToast('Error', 'Please select a queue.', 'error');
            return;
        }

        assignQueueToOpportunity({ opportunityId: this.recordId, queueId: this.selectedQueueId })
            .then(() => {
                this.showToast('Success', 'Queue assigned successfully.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}