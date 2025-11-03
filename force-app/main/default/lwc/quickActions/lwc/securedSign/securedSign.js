import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import uploadAndSignWorkFile from '@salesforce/apex/SecuredSignFacade.uploadAndSignWorkFile';

const FIRST_NAME = 'Colby';
const LAST_NAME  = 'Edell';
const EMAIL      = 'colby@torchdesigns.com';

export default class SignEmbed extends LightningElement {
  @api recordId;
  isLoading = true;
  iframeSrc;
  originOk;
  payload;
  _started = false;
  _onMsg = null;

  @wire(CurrentPageReference)
  setPageRef(pr) {
    if (!this.recordId) {
      this.recordId = pr?.state?.recordId || pr?.attributes?.recordId;
    }
    this._maybeStart();
  }

  renderedCallback() {
    this._maybeStart();
  }

  disconnectedCallback() {
    if (this._onMsg) {
      window.removeEventListener('message', this._onMsg);
      this._onMsg = null;
    }
  }

  _maybeStart() {
    if (this._started || !this.recordId) return;
    this._started = true;
    this.init();
  }

  async init() {
    try {
      const r = await uploadAndSignWorkFile({
        workFileId: this.recordId,
        email: EMAIL,
        firstName: FIRST_NAME,
        lastName: LAST_NAME
      });

      const signingKey = r?.signingKey || r?.SigningKey;
      const linkUrl    = r?.weSignUrl  || r?.url;
      const docRefRaw  = r?.documentRef || r?.docRef || r?.DocumentReference;
      const vfUrl =
    'https://kimes24--qa--c.sandbox.vf.force.com/apex/SS_UpdateRecordPage'
    + '?recordId=' + this.recordId
    + '&event=done'
    + '&docRef=' + encodeURIComponent(docRefRaw);

      if (!signingKey || !linkUrl || !docRefRaw) throw new Error('Missing signingKey/url/docRef');

      const base = linkUrl.includes('/Utilities/LinkAccess.aspx')
        ? linkUrl.replace('/Utilities/LinkAccess.aspx', '/Embedded/Sign.aspx')
        : linkUrl;

      this.originOk = new URL(base).origin;
      this.payload = {
        requestInfo: {
          SigningKey: signingKey,
          Embedded: true,
          DocumentReference: docRefRaw,
          FirstName: FIRST_NAME,
          LastName:  LAST_NAME,
          Email:     EMAIL
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
          window.location.href = vfUrl;
        }
      };
      window.addEventListener('message', this._onMsg);

    } catch (e) {
      alert(e?.body?.message || e.message || 'Upload/prepare error');
    } finally {
      this.isLoading = false;
    }
  }

  _post() {
    try {
      const frame = this.template.querySelector('iframe[data-id="host"]');
      if (!frame) return;
      frame.contentWindow.postMessage(this.payload, this.originOk);
    } catch (e) {}
  }
}
