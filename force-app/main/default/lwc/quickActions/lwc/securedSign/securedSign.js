import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import uploadAndSignWorkFile from '@salesforce/apex/SecuredSignFacade.uploadAndSignWorkFile';

const FIRST_NAME = 'Colby';
const LAST_NAME  = 'Edell';
const EMAIL      = 'colby@torchdesigns.com';
const VF_BASE    = 'https://kimes24--qa--c.sandbox.vf.force.com/apex/SS_UpdateRecordPage';

export default class SignEmbed extends LightningElement {
  @api recordId;

  isLoading = false;  
  hasStarted = false;
  iframeSrc;
  originOk;
  payload;
  _onMsg = null;

  @wire(CurrentPageReference)
  setPageRef(pr) {
    if (!this.recordId) {
      this.recordId = pr?.state?.recordId || pr?.attributes?.recordId;
    }
  }

  handleStart() {
    if (this.hasStarted) {
      return;
    }
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
    this.isLoading = true;
    try {
      const r = await uploadAndSignWorkFile({
        workFileId: this.recordId,
        email: EMAIL,
        firstName: FIRST_NAME,
        lastName: LAST_NAME
      });

      const signingKey = r?.signingKey;
      const linkUrl    = r?.weSignUrl;
      const docRefRaw  = r?.documentRef;

      if (!signingKey || !linkUrl || !docRefRaw) {
        throw new Error('Secured Signing returned incomplete data.');
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
    } catch (e) {
      const msg = e?.body?.message || e.message || 'Secured Signing failed.';
      alert(msg);
      this.dispatchEvent(new CloseActionScreenEvent());
    } finally {
      this.isLoading = false;
    }
  }

  _post() {
    const frame = this.template.querySelector('iframe[data-id="host"]');
    if (!frame) return;
    frame.contentWindow.postMessage(this.payload, this.originOk);
  }

  disconnectedCallback() {
    if (this._onMsg) {
      window.removeEventListener('message', this._onMsg);
      this._onMsg = null;
    }
  }
}
