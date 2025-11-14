import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import startUploadAndSign from '@salesforce/apex/SecuredSignFacade.startUploadAndSign';
import annotateWorkFile from '@salesforce/apex/PDFRestService.annotateWorkFile';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

const CHANNEL     = '/event/Async_Callout_Notification__e';
const STATUS_FIELD = 'Work_File__c.Status__c';

const FIRST_NAME = 'Colby';
const LAST_NAME  = 'Edell';
const EMAIL      = 'colby@torchdesigns.com';
const VF_BASE    = 'https://kimes24--qa--c.sandbox.vf.force.com/apex/SS_UpdateRecordPage';

export default class SignEmbed extends LightningElement {
  @api recordId;

  hasStarted   = false;
  isAnnotating = false;
  isSigning    = false;

  workFileStatus;

  iframeSrc;
  originOk;
  payload;
  _onMsg = null;
  subscription = null;

  @wire(CurrentPageReference)
  setPageRef(pr) {
    if (!this.recordId) {
      this.recordId = pr?.state?.recordId || pr?.attributes?.recordId;
    }
  }

  @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
  wiredWF({ data }) {
    if (data) {
      this.workFileStatus = data.fields.Status__c.value;
    }
  }

  connectedCallback() {
    this.subscribeToEvents();
    this.registerErrorListener();
  }

  subscribeToEvents() {
    const messageCallback = (eventReceived) => {
      const p = eventReceived?.data?.payload;
      if (!p) return;
      if (p.Context__c !== this.recordId) return;

      this.isSigning = false;

      if (p.Status__c === 'SUCCESS') {
        const data = JSON.parse(p.Message__c);
        this.setupIframe(data);
      } else {
        alert(p.Message__c || 'Secured Signing failed.');
        this.dispatchEvent(new CloseActionScreenEvent());
      }
    };

    subscribe(CHANNEL, -1, messageCallback).then((response) => {
      this.subscription = response;
    });
  }

  registerErrorListener() {
    onError((error) => {
      console.error('EMP error: ', JSON.stringify(error));
    });
  }

  disconnectedCallback() {
    if (this.subscription) {
      unsubscribe(this.subscription, () => {});
    }
    if (this._onMsg) {
      window.removeEventListener('message', this._onMsg);
      this._onMsg = null;
    }
  }

  handleStart() {
    if (this.hasStarted) return;
    if (this._isBackNavigation()) {
      this.dispatchEvent(new CloseActionScreenEvent());
      return;
    }

    this.hasStarted = true;
    this.init();
  }

  _isBackNavigation() {
    try {
      const entries = performance.getEntriesByType('navigation');
      return entries && entries[0] && entries[0].type === 'back_forward';
    } catch (e) {
      return false;
    }
  }

  async init() {
    try {
      const status = (this.workFileStatus || '').toLowerCase();

      if (status === 'draft') {
        this.isAnnotating = true;
        await annotateWorkFile({ workFileId: this.recordId });
        this.isAnnotating = false;
      }

      this.isSigning = true;
      await startUploadAndSign({
        workFileId: this.recordId,
        email: EMAIL,
        firstName: FIRST_NAME,
        lastName: LAST_NAME
      });
    } catch (e) {
      this.isAnnotating = false;
      this.isSigning = false;
      const msg = e?.body?.message || e.message || 'Secured Signing start failed.';
      alert(msg);
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  }

  setupIframe(data) {
    const signingKey = data?.signingKey;
    const linkUrl    = data?.weSignUrl;
    const docRefRaw  = data?.documentRef;

    if (!signingKey || !linkUrl || !docRefRaw) {
      alert('Secured Signing returned incomplete data.');
      this.dispatchEvent(new CloseActionScreenEvent());
      return;
    }

    const vfUrl =
      `${VF_BASE}?recordId=${this.recordId}&event=done&docRef=${encodeURIComponent(docRefRaw)}`;

    const base = linkUrl.includes('/Utilities/LinkAccess.aspx')
      ? linkUrl.replace('/Utilities/LinkAccess.aspx', '/Embedded/Sign.aspx')
      : linkUrl;

    this.originOk = new URL(base).origin;
    this.payload = {
      requestInfo: {
        SigningKey:        signingKey,
        Embedded:          true,
        DocumentReference: docRefRaw,
        FirstName:         FIRST_NAME,
        LastName:          LAST_NAME,
        Email:             EMAIL
      }
    };

    const parentUrl = encodeURIComponent(window.location.href);
    this.iframeSrc = `${base}#${parentUrl}`;

    this._onMsg = (e) => {
      if (e.origin !== this.originOk) return;
      const msg = e.data || {};
      if (msg.status === 'initialised') {
        this._post();
      }
      if (msg.status === 'done') {
        window.location.replace(vfUrl);
      }
    };
    window.addEventListener('message', this._onMsg);
  }

  _post() {
    const frame = this.template.querySelector('iframe[data-id="host"]');
    if (!frame) return;
    frame.contentWindow.postMessage(this.payload, this.originOk);
  }
}
