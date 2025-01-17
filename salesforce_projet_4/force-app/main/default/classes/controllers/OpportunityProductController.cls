public with sharing class OpportunityProductController {
    private static final OpportunityProductService service = OpportunityProductService.getInstance();
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityProducts(Id opportunityId) {
        try {
            return service.getOpportunityProducts(opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isSystemAdmin() {
        try {
            return service.isSystemAdmin();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteOpportunityProduct(Id lineItemId) {
        try {
            service.deleteOpportunityProduct(lineItemId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateProductStock(Id opportunityId) {
        try {
            service.updateProductStocks(opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}