/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
private class OpportunityProductServiceTest {
    @TestSetup
    static void setupTestData() {
        // Créer un produit test
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            QuantityInStock__c = 100
        );
        insert prod;
        
        // Créer entrée dans PricebookEntry
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
        // Créer une opportunité
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;
        
        // Ajouter produit à l'opportunité
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert oli;
    }
    
    @IsTest
    static void testGetInstance() {
        // Test du pattern Singleton
        OpportunityProductService service1 = OpportunityProductService.getInstance();
        OpportunityProductService service2 = OpportunityProductService.getInstance();
        
        System.assertEquals(service1, service2, 'Should return the same instance');
    }
    
    @IsTest
    static void testGetOpportunityProducts() {
        // Récupérer l'opportunité test
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItem> products = OpportunityProductService.getInstance()
            .getOpportunityProducts(opp.Id);
        Test.stopTest();
        
        System.assertEquals(1, products.size(), 'Should return 1 product');
        System.assertEquals('Test Product', products[0].Product2.Name, 
                          'Should return correct product name');
    }
    
    @IsTest
    static void testDeleteOpportunityProduct() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        
        Test.startTest();
        OpportunityProductService.getInstance().deleteOpportunityProduct(oli.Id);
        Test.stopTest();
        
        List<OpportunityLineItem> remainingOlis = [SELECT Id FROM OpportunityLineItem];
        System.assertEquals(0, remainingOlis.size(), 'Product should be deleted');
    }
    
    @IsTest
    static void testProcessClosedWonOpportunity() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.StageName = 'Closed Won';
        
        Test.startTest();
        OpportunityProductService.getInstance().processClosedWonOpportunity(opp, oldOpp);
        Test.stopTest();
        
        Product2 updatedProduct = [SELECT QuantityInStock__c FROM Product2 LIMIT 1];
        System.assertEquals(90, updatedProduct.QuantityInStock__c, 
                          'Stock should be reduced by 10');
    }
    
    @IsTest
    static void testProcessClosedWonOpportunityInsufficientStock() {
        // Mettre à jour le stock à une valeur insuffisante
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        prod.QuantityInStock__c = 5;
        update prod;
        
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Opportunity oldOpp = opp.clone(true, true, true, true);
        opp.StageName = 'Closed Won';
        
        Test.startTest();
        try {
            OpportunityProductService.getInstance().processClosedWonOpportunity(opp, oldOpp);
            System.assert(false, 'Should throw an exception');
        } catch (OpportunityProductException e) {
            System.assert(e.getMessage().contains('Not enough products available'), 
                         'Should throw insufficient stock exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIsSystemAdmin() {
        Test.startTest();
        Boolean isAdmin = OpportunityProductService.getInstance().isSystemAdmin();
        Test.stopTest();
        
        // Le résultat dépendra des permissions de l'utilisateur de test
        System.assertNotEquals(null, isAdmin, 'Should return a boolean value');
    }
}