import { LightningElement, api, track, wire } from 'lwc';
import getQueues from '@salesforce/apex/AssignOpportunityQueueController.getQueues';
import getOpportunityQueue from '@salesforce/apex/AssignOpportunityQueueController.getOpportunityQueue';
import assignQueueToOpportunity from '@salesforce/apex/AssignOpportunityQueueController.assignQueueToOpportunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class AssignOpportunityQueue extends LightningElement {
    @api recordId; 
    @track queueOptions = [];
    @track selectedQueueId;
    wiredCurrentQueueResult;

    @wire(getQueues)
    wiredQueues({ error, data }) {
        if (data) {
            this.queueOptions = data.map(queue => ({
                label: queue.Name,
                value: queue.Id
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load queues', 'error');
        }
    }

    @wire(getOpportunityQueue, { opportunityId: '$recordId' })
    wiredCurrentQueue(result) {
        this.wiredCurrentQueueResult = result;
        const { data, error } = result;
        if (data) {
            this.selectedQueueId = data;
        } else if (error) {
            this.showToast('Error', 'Failed to load current queue', 'error');
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
