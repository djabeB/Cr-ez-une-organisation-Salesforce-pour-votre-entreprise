//C:\Users\bouke\Documents\OPC4\Cr-ez-une-organisation-Salesforce-pour-votre-entreprise\salesforce_projet_4\force-app\main\default\classes\services\OpportunityProductService.cls
public with sharing class OpportunityProductService {
    private static OpportunityProductService instance;
    
    // Pattern Singleton
    public static OpportunityProductService getInstance() {
        if (instance == null) {
            instance = new OpportunityProductService();
        }
        return instance;
    }
    
    // Méthode pour récupérer les produits d'une opportunité
    public List<OpportunityLineItem> getOpportunityProducts(Id opportunityId) {
        try {
            return [
                SELECT Id, Product2.Name, UnitPrice, TotalPrice, Quantity, 
                       Product2.QuantityInStock__c, Product2Id, Opportunity.Name
                FROM OpportunityLineItem 
                WHERE OpportunityId = :opportunityId
                WITH SECURITY_ENFORCED
            ];
        } catch (Exception e) {
            throw new OpportunityProductException('Error retrieving opportunity products: ' + e.getMessage());
        }
    }
    
    public Boolean isSystemAdmin() {
        try {
            return [SELECT Id 
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId = :UserInfo.getUserId() 
                    AND PermissionSet.PermissionsModifyAllData = true 
                    AND PermissionSet.PermissionsViewAllData = true].size() > 0;
        } catch (Exception e) {
            throw new OpportunityProductException('Error checking admin profile: ' + e.getMessage());
        }
    }
    
    // Méthode pour supprimer un produit d'opportunité
    public void deleteOpportunityProduct(Id lineItemId) {
        try {
            OpportunityLineItem lineItem = [
                SELECT Id 
                FROM OpportunityLineItem 
                WHERE Id = :lineItemId 
                WITH SECURITY_ENFORCED
            ];
            
            if (!Schema.sObjectType.OpportunityLineItem.isDeletable()) {
                throw new OpportunityProductException('Insufficient permissions to delete opportunity line items');
            }
            
            delete lineItem;
        } catch (Exception ex) {
            throw new OpportunityProductException(ex.getMessage());
        }
    }
    
    // Méthode pour vérifier et mettre à jour les stocks
    public void processClosedWonOpportunity(Opportunity newOpp, Opportunity oldOpp) {
        System.debug(newOpp);
        if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            validateAndUpdateStock(newOpp.Id);
        }
    }
    
    private void validateAndUpdateStock(Id opportunityId) {
        List<OpportunityLineItem> lineItems = getOpportunityProducts(opportunityId);
        validateStockQuantities(lineItems);
        updateProductStock(lineItems);
    }
    
    private void validateStockQuantities(List<OpportunityLineItem> lineItems) {
        for (OpportunityLineItem oli : lineItems) {
            if (oli.Quantity > oli.Product2.QuantityInStock__c) {
                throw new OpportunityProductException(
                    'Not enough products available for opportunity "' + oli.Product2.Name + '"!');
            }
        }
    }
    
    private void updateProductStock(List<OpportunityLineItem> lineItems) {
        List<Product2> productsToUpdate = new List<Product2>();
        
        for (OpportunityLineItem oli : lineItems) {
            productsToUpdate.add(new Product2(
                Id = oli.Product2Id,
                QuantityInStock__c = oli.Product2.QuantityInStock__c - oli.Quantity
            ));
        }
        
        if (!Schema.sObjectType.Product2.isUpdateable()) {
            throw new OpportunityProductException('Insufficient permissions to update products');
        }
        
        update productsToUpdate;
    }
    
}