import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/Work_File__c.Status__c';
import getFileVersions from '@salesforce/apex/FileVersionsController.getFileVersions';
import updateMarkAsSigned from '@salesforce/apex/FileVersionsController.updateMarkAsSigned';
import { refreshApex } from '@salesforce/apex';
const WORKFILE_FIELDS = [STATUS_FIELD];

export default class FileVersionDisplay extends LightningElement {
    pdfHeight;

    @api recordId; // Automatically populated with the current record's ID [31, 32]
    @track isLoading = true; // Controls spinner visibility [21, 29]
    @track error; // Stores any error messages [16, 17, 33]

    @track versionOptions = []; // Stores options for the combobox [16, 24, 25, 26]
    @track currentFileName = 'File Versions'; // Default title for the lightning-card
    @track selectedVersionId; // Stores the ID of the selected ContentVersion

    wiredData;

    allVersionsData; // Private property to store all fetched version data for client-side lookup

    selectedOption;
    @wire(getRecord, { recordId: '$recordId', fields: WORKFILE_FIELDS })
    wiredWorkFile;
    get versionURL() {
        return this.selectedOption?.versionURL.split('.force.com')[1];
    }

    get versionName() {
        return this.selectedOption?.fileName;
    }

    get versionNumber() {
        return this.selectedOption?.label;
    }

    get isLatestMarked() {
        const latest = this.allVersionsData?.find(option => option.isLatest);
        return latest?.latestSigned || false;
    }

    columns = [
        { label: 'File Name', fieldName: 'fileName' },
        { label: 'Version', fieldName: 'label' },
        { label: 'Change Reason', fieldName: 'reason' },
        { label: 'Description', fieldName: 'description' },
        { label: 'Upload Date', fieldName: 'createdDate', type: 'date',
            typeAttributes: {
                year: "numeric",
                month: "long",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit"
            }
        },
        { label: 'Last Version', fieldName: 'isLatest', type: 'boolean' },
        { label: 'Latest Signed', fieldName: 'latestSigned', type: 'boolean' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Preview',
                name: 'preview_file',
                title: 'Preview',
                disabled: { fieldName: 'disabled' }
            }
        }
    ];

    @wire(getFileVersions, { recordId: '$recordId' })
    wiredFileVersions(wiredData) {
        this.wiredData = wiredData;
        console.log('HERE');

        const { data, error } = wiredData;


        this.isLoading = false; // Hide spinner once data is received or error occurs
        if (data) {
            this.allVersionsData = data; // Store all data for client-side lookup
            this.versionOptions = JSON.parse(JSON.stringify(data)); // Populate combobox options

            if (this.versionOptions?.length > 0) {
                // Find the latest version to set as default
                const latestVersion = this.versionOptions.find(version => version.isLatest);
                if (latestVersion) {
                    latestVersion.disabled = true;
                    this.currentFileName = latestVersion.fileName || 'File Versions'; // Set card title to latest file name
                    this.selectedVersionId = latestVersion.value;
                    this.selectedOption = latestVersion;
                } else {
                    this.versionOptions[0].disabled = true;
                    this.currentFileName = this.versionOptions[0].fileName || 'File Versions';
                    this.selectedVersionId = this.versionOptions[0].value;
                    this.selectedOption = this.versionOptions[0];
                }
            } else {
                this.currentFileName = 'No Files Linked';
                this.selectedVersionFileName = 'N/A';
            }
            this.error = undefined;
        } else if (error) {
            this.error = 'Failed to load file versions: ' + JSON.stringify(error);
            this.currentFileName = 'Error Loading Files';
            this.selectedVersionFileName = 'Error';
            console.error('Error loading file versions:', error);
        }
    }

    // handleVersionChange(event) {
    //     this.selectedVersionId = event.detail.value;

    //     const selectedOption = this.allVersionsData.find(option => option.value === this.selectedVersionId);
    //     if (selectedOption) {
    //         this.selectedOption = selectedOption;
    //     }
    // }

    connectedCallback() {
        this.updateScreenSize();
        window.addEventListener('resize', this.updateScreenSize.bind(this));
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.updateScreenSize.bind(this));
    }

    updateScreenSize() {
        this.pdfHeight = window.innerHeight * 0.6;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'preview_file') {
            // Implement your edit logic here, e.g., navigate to a record page
            console.log('Edit Account:', row.value);
            let allVersions = JSON.parse(JSON.stringify(this.allVersionsData));
            allVersions.forEach(option => {
                if (option.value === row.value) {
                    this.selectedOption = option;
                    option.disabled = true;
                } else {
                    option.disabled = false;
                }

            });
            this.versionOptions = allVersions;
        }
    }
    async handleRefresh() {
        console.log('REFRESH');

        await refreshApex(this.wiredData);
    }
    async loadWorkFile(workFileId) {
        try {
            const workFiles = await getWorkFilesByIds({ ids: [workFileId] });
            if (workFiles.length > 0) {
                this.workFile = workFiles[0];
                console.log('Updated Work_File:', this.workFile);
            }
        } catch (error) {
            console.error('Failed to load Work_File__c', error);
        }
    }
    async handleMarkAsSigned() {
        console.log('handleMarkAsSigned');

        const latestOption = this.allVersionsData.find(option => option.isLatest);
        if (!latestOption || !latestOption.value) {
            console.warn('No file selected, cannot mark as signed');
            return;
        }
        const contentVersionId = latestOption.value;
        const workFileId = this.recordId;
        console.log('Marking as signed contentVersionId:', contentVersionId, 'workFileId:', workFileId);
        await updateMarkAsSigned({
            contentVersionId,
            workFileId
        });
        await refreshApex(this.wiredData);
        await refreshApex(this.wiredWorkFile);
    }
}