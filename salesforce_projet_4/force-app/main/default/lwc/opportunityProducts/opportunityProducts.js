import { LightningElement, api, wire } from 'lwc';
import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import isSystemAdmin from '@salesforce/apex/OpportunityProductController.isSystemAdmin';
import deleteOpportunityProduct from '@salesforce/apex/OpportunityProductController.deleteOpportunityProduct';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

// Import des Custom Labels
import NO_PRODUCTS_MESSAGE from '@salesforce/label/c.No_Products_Message';
import STOCK_WARNING_MESSAGE from '@salesforce/label/c.Stock_Warning_Message';
import PRODUCT_NAME_COLUMN from '@salesforce/label/c.Product_Name_Column';
import UNIT_PRICE_COLUMN from '@salesforce/label/c.Unit_Price_Column';
import TOTAL_PRICE_COLUMN from '@salesforce/label/c.Total_Price_Column';
import QUANTITY_COLUMN from '@salesforce/label/c.Quantity_Column';
import STOCK_QUANTITY_COLUMN from '@salesforce/label/c.Stock_Quantity_Column';
import DELETE_ACTION from '@salesforce/label/c.Delete_Action';
import VIEW_PRODUCT_ACTION from '@salesforce/label/c.View_Product_Action';

export default class OpportunityProducts extends NavigationMixin(LightningElement) {
    label = {
        noProducts: NO_PRODUCTS_MESSAGE,
        stockWarning: STOCK_WARNING_MESSAGE,
        productName: PRODUCT_NAME_COLUMN,
        unitPrice: UNIT_PRICE_COLUMN,
        totalPrice: TOTAL_PRICE_COLUMN,
        quantity: QUANTITY_COLUMN,
        stockQuantity: STOCK_QUANTITY_COLUMN,
        deleteAction: DELETE_ACTION,
        viewProduct: VIEW_PRODUCT_ACTION
    };

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
                label: this.label.productName, 
                fieldName: 'productName', 
                type: 'text'
            },
            { 
                label: this.label.unitPrice, 
                fieldName: 'UnitPrice', 
                type: 'currency'
            },
            { 
                label: this.label.totalPrice, 
                fieldName: 'TotalPrice', 
                type: 'currency'
            },
            { 
                label: this.label.quantity, 
                fieldName: 'quantity', 
                type: 'number',
                cellAttributes: {
                    class: { fieldName: 'quantityClass' }
                }
            },
            { 
                label: this.label.stockQuantity, 
                fieldName: 'quantityInStock', 
                type: 'number',
                cellAttributes: {
                    class: { fieldName: 'quantityClass' }
                }
            }
        ];
    
        const actions = this.isAdmin ? 
            [
                { label: this.label.deleteAction, name: 'delete', iconName: 'utility:delete' },
                { label: this.label.viewProduct, name: 'view', iconName: 'utility:preview' }
            ] : 
            [
                { label: this.label.deleteAction, name: 'delete', iconName: 'utility:delete' }
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