public class OpportunityTriggerHandler {
    private static final OpportunityProductService service = OpportunityProductService.getInstance();
    
    public void run() {
        if (Trigger.isBefore && Trigger.isUpdate) {
            handleBeforeUpdate();
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
}