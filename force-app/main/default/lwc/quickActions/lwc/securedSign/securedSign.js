import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import startUploadAndSign from '@salesforce/apex/SecuredSignFacade.startUploadAndSign';
import annotateWorkFile from '@salesforce/apex/PDFRestService.annotateWorkFile';
import getUpdateRecordPageUrl from '@salesforce/apex/SecuredSignService.getUpdateRecordPageUrl';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

import USER_ID from '@salesforce/user/Id';
import USER_FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';
import USER_LAST_NAME_FIELD from '@salesforce/schema/User.LastName';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';

const CHANNEL      = '/event/Async_Callout_Notification__e';
const STATUS_FIELD = 'Work_File__c.Status__c';

export default class SignEmbed extends LightningElement {
  @api recordId;

  hasStarted   = false;
  isAnnotating = false;
  isSigning    = false;

  workFileStatus;

  userFirstName;
  userLastName;
  userEmail;

  vfBaseUrl;

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

  @wire(getRecord, {
    recordId: USER_ID,
    fields: [USER_FIRST_NAME_FIELD, USER_LAST_NAME_FIELD, USER_EMAIL_FIELD]
  })
  wiredUser({ data, error }) {
    if (data) {
      this.userFirstName = data.fields.FirstName.value;
      this.userLastName  = data.fields.LastName.value;
      this.userEmail     = data.fields.Email.value;
    } else if (error) {
      console.error('Error loading current user', error);
      this.userFirstName = 'User';
      this.userLastName  = '';
      this.userEmail     = '';
    }
  }

  @wire(getUpdateRecordPageUrl)
  wiredVfBase({ data, error }) {
    if (data) {
      this.vfBaseUrl = data;
    } else if (error) {
      console.error('Error loading VF base URL', error);
      this.vfBaseUrl = window.location.origin + '/apex/SS_UpdateRecordPage';
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
    if (!this.userEmail || !this.vfBaseUrl) {
      alert('Please wait a moment and try again.');
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
      if (status==='signed') return;
      if (status === 'draft') {
        this.isAnnotating = true;
        await annotateWorkFile({ workFileId: this.recordId });
        this.isAnnotating = false;
      }

      this.isSigning = true;
      await startUploadAndSign({
        workFileId: this.recordId,
        email: this.userEmail,
        firstName: this.userFirstName,
        lastName: this.userLastName
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
      `${this.vfBaseUrl}?recordId=${this.recordId}&event=done&docRef=${encodeURIComponent(docRefRaw)}`;

    const base = linkUrl.includes('/Utilities/LinkAccess.aspx')
      ? linkUrl.replace('/Utilities/LinkAccess.aspx', '/Embedded/Sign.aspx')
      : linkUrl;

    this.originOk = new URL(base).origin;
    this.payload = {
      requestInfo: {
        SigningKey:        signingKey,
        Embedded:          true,
        DocumentReference: docRefRaw,
        FirstName:         this.userFirstName,
        LastName:          this.userLastName,
        Email:             this.userEmail
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
