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
private class OpportunityProductControllerTest {
    @TestSetup
    static void setupTestData() {
        // Créer un produit test
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            QuantityInStock__c = 100
        );
        insert prod;
        Product2 prodUpdateStock = new Product2(
            Name = 'Test product update stock',
            IsActive = true,
            QuantityInStock__c = 100
        );
        insert prodUpdateStock;
        // Créer entrée dans PricebookEntry
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        
         PricebookEntry pbeStock = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prodUpdateStock.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbeStock;
        
        // Créer une opportunité
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;
        
         Opportunity oppUpdateStock = new Opportunity(
            Name = 'Test Opportunity Update Stock',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert oppUpdateStock;
        
        // Ajouter produit à l'opportunité
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert oli;
        
        OpportunityLineItem oliUpdateStock = new OpportunityLineItem(
            OpportunityId = oppUpdateStock.Id,
            PricebookEntryId = pbeStock.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert oliUpdateStock;
    }
    
    @IsTest
    static void testGetOpportunityProducts() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItem> products = OpportunityProductController.getOpportunityProducts(opp.Id);
        Test.stopTest();
        
        System.assertEquals(1, products.size(), 'Should return 1 product');
        System.assertEquals('Test Product', products[0].Product2.Name, 
                          'Should return correct product name');
    }
    
    @IsTest
    static void testGetOpportunityProductsError() {
        Test.startTest();
        try {
            OpportunityProductController.getOpportunityProducts(null);
            System.assert(false, 'Should throw an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIsSystemAdmin() {
        Test.startTest();
        Boolean isAdmin = OpportunityProductController.isSystemAdmin();
        Test.stopTest();
        
        System.assertNotEquals(null, isAdmin, 'Should return a boolean value');
    }
    
    @IsTest
    static void testDeleteOpportunityProduct() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem Where opportunityId =: testOpp.Id LIMIT 1];
        
        Test.startTest();
        OpportunityProductController.deleteOpportunityProduct(oli.Id);
        Test.stopTest();
        
        List<OpportunityLineItem> remainingOlis = [SELECT Id FROM OpportunityLineItem Where opportunityId =: testOpp.Id LIMIT 1];
        System.assertEquals(0, remainingOlis.size(), 'Product should be deleted');
    }
    
    @IsTest
    static void testDeleteOpportunityProductError() {
        Test.startTest();
        try {
            OpportunityProductController.deleteOpportunityProduct(null);
            System.assert(false, 'Should throw an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception should be thrown');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateProductStock() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity Update Stock' LIMIT 1];
        Test.startTest();
        
        //testOpp.StageName = 'Closed Won';
        //update testOpp;
        OpportunityProductController.updateProductStock(testOpp.Id);

        Product2 ProductUpdateStock =  [SELECT Id, QuantityInStock__c  from Product2 Where Name = 'Test product update stock' LIMIT 1];
        
        System.assert(ProductUpdateStock.QuantityInStock__c == 90, 'Update success' + ProductUpdateStock.QuantityInStock__c);
        Test.stopTest();
        
    }
    
    
    
    
}