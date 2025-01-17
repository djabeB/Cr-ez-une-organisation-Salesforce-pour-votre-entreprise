public class OpportunityTriggerHandler {
    private static final OpportunityProductService service = OpportunityProductService.getInstance();
    
    public void run() {
        if (Trigger.isBefore && Trigger.isUpdate) {
            handleBeforeUpdate();
        } else if (Trigger.isAfter && Trigger.isUpdate) {
            handleAfterUpdate();
        }
    }
    
    private void handleBeforeUpdate() {
        for (Opportunity newOpp : (List<Opportunity>) Trigger.new) {
            Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(newOpp.Id);
            try {
                service.processClosedWonOpportunity(newOpp, oldOpp);
            } catch (OpportunityProductException e) {  // Utilisez simplement OpportunityProductException
                newOpp.addError(e.getMessage());
            }
        }
    }

    private void handleAfterUpdate() {
        List<OpportunityProductUpdate_e__e> events = new List<OpportunityProductUpdate_e__e>();
        
        for (Opportunity newOpp : (List<Opportunity>) Trigger.new) {
            Opportunity oldOpp = (Opportunity) Trigger.oldMap.get(newOpp.Id);
            if (newOpp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                events.add(new OpportunityProductUpdate_e__e(
                    Opportunity_Id_c__c = newOpp.Id
                ));
            }
        }
        
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
}