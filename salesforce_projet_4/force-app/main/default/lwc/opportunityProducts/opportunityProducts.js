import { LightningElement, api, wire } from 'lwc';
import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import isSystemAdmin from '@salesforce/apex/OpportunityProductController.isSystemAdmin';
import deleteOpportunityProduct from '@salesforce/apex/OpportunityProductController.deleteOpportunityProduct';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class OpportunityProducts extends NavigationMixin(LightningElement) {
    @api recordId;
    opportunityProducts;
    columns;
    isAdmin = false;
    wiredProductsResult;
    subscription = {};
    channelName = '/event/OpportunityProductUpdate_e__e';

    connectedCallback() {
        this.checkUserProfile();
        this.registerErrorListener();
        this.handleSubscribe();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    // Gestion des événements de plateforme
    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('Événement reçu:', JSON.stringify(response));
            if (response.data.payload.Opportunity_Id_c__c === this.recordId) {
                this.refresh();
            }
        };

        subscribe(this.channelName, -1, messageCallback)
            .then(response => {
                console.log('Abonnement réussi');
                this.subscription = response;
            })
            .catch(error => {
                console.error('Erreur lors de l\'abonnement:', error);
            });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription)
            .then(() => {
                console.log('Désabonnement réussi');
            })
            .catch(error => {
                console.error('Erreur lors du désabonnement:', error);
            });
    }

    registerErrorListener() {
        onError(error => {
            console.error('Erreur EMP API:', error);
        });
    }

    async checkUserProfile() {
        try {
            this.isAdmin = await isSystemAdmin();
            this.initializeColumns();
            console.log('this.isAdmin: ' + this.isAdmin)
        } catch (error) {
            console.error('Error checking profile:', error);
        }
    }

    initializeColumns() {
        this.columns = [
            { 
                label: 'Nom du produit', 
                fieldName: 'productName', 
                type: 'text'
            },
            { 
                label: 'Prix unitaire', 
                fieldName: 'UnitPrice', 
                type: 'currency'
            },
            { 
                label: 'Prix total', 
                fieldName: 'TotalPrice', 
                type: 'currency'
            },
            { 
                label: 'Quantité', 
                fieldName: 'quantity', 
                type: 'number',
                cellAttributes: {
                    class: { fieldName: 'quantityClass' }
                }
            },
            { 
                label: 'Quantité en stock', 
                fieldName: 'quantityInStock', 
                type: 'number',
                cellAttributes: {
                    class: { fieldName: 'quantityClass' }
                }
            }
        ];
    
        const actions = this.isAdmin ? 
            [
                { label: 'Supprimer', name: 'delete', iconName: 'utility:delete' },
                { label: 'Voir produit', name: 'view', iconName: 'utility:preview' }
            ] : 
            [
                { label: 'Supprimer', name: 'delete', iconName: 'utility:delete' }
            ];
    
        this.columns.push({
            type: 'action',
            typeAttributes: { rowActions: actions }
        });
    }
    
    @wire(getOpportunityProducts, { opportunityId: '$recordId' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        const { data, error } = result;
        if (data) {
            this.opportunityProducts = data.map(item => {
                const hasQuantityError = item.Product2.QuantityInStock__c - item.Quantity < 0;
                return {
                    ...item,
                    productName: item.Product2.Name,
                    quantityInStock: item.Product2.QuantityInStock__c,
                    quantity: item.Quantity,
                    quantityClass: hasQuantityError ? 'slds-button_icon-error' : ''
                };
            });
        } else if (error) {
            console.error('Error loading products:', error);
        }
    }

    @api
    async refresh() {
        await refreshApex(this.wiredProductsResult);
    }

    isQuantityError(item) {
        return item.Quantity > item.Product2.QuantityInStock__c;
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'delete':
                await this.deleteProduct(row.Id);
                break;
            case 'view':
                if (this.isAdmin) {
                    this.navigateToProduct(row.Product2Id);
                }
                break;
        }
    }

    async deleteProduct(productId) {
        try {
            await deleteOpportunityProduct({ lineItemId: productId });
            await refreshApex(this.wiredProductsResult);
        } catch (error) {
            console.error('Error deleting product:', error);
        }
    }

    navigateToProduct(productId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }

    get hasProducts() {
        return this.opportunityProducts?.length > 0;
    }

    get hasStockWarning() {
        return this.opportunityProducts?.some(product => 
            this.isQuantityError(product)
        );
    }
}