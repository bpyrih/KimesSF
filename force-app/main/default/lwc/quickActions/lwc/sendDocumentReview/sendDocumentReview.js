import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from 'lightning/navigation';
import sentReview from "@salesforce/apex/WorkFileSignController.sentReview";

export default class SendDocumentReview extends NavigationMixin(LightningElement) {
    @api
    recordId;

    launched = false;
    url;
    
    get loading() {
        return !this.recordId || !this.url;
    }

    connectedCallback() {
        window.addEventListener('message', this.handleMessage.bind(this));
    }

    handleMessage(message) {
        console.log(JSON.stringify(message))
    }

    renderedCallback() {
        console.log(this.recordId);
        if (this.recordId && !this.launched) {
            this.launched = true;
            
            sentReview({workFileId : this.recordId})
            .then(result => {
                console.log(result);
                this.url = result;
                // this[NavigationMixin.GenerateUrl]({
                //     type: 'standard__webPage',
                //     attributes: {
                //         url: result
                //     }
                // }).then((url) => {
                //     this.url = url;
                // });
                console.log('result');
                // this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                console.log(error);
                this.dispatchEvent(new CloseActionScreenEvent());
            });
        }
    }

    handleClick() {
        console.log('asdasdasdasd');
        
        window.close();
    }
}