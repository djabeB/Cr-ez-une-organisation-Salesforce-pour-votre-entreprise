trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete) {
    Set<Id> opportunityIds = new Set<Id>();
    
    // Collecter les IDs d'opportunités affectées
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (OpportunityLineItem oli : Trigger.new) {
            opportunityIds.add(oli.OpportunityId);
        }
    }
    if (Trigger.isDelete) {
        for (OpportunityLineItem oli : Trigger.old) {
            opportunityIds.add(oli.OpportunityId);
        }
    }
    
    // Publier un événement pour chaque opportunité affectée
    List<OpportunityProductUpdate_e__e> events = new List<OpportunityProductUpdate_e__e>();
    for (Id oppId : opportunityIds) {
        OpportunityProductUpdate_e__e evt = new OpportunityProductUpdate_e__e(
            Opportunity_Id_c__c = oppId
        );
        events.add(evt);
    }
    
    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}