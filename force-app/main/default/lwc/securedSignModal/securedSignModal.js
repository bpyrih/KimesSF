import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class SecuredSignModal extends LightningModal {
  @api workFileId;
}
