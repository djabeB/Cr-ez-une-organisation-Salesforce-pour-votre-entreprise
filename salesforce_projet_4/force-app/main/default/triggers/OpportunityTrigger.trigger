// OpportunityTrigger.trigger
trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update) {
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    System.debug('OpportunityTrigger.trigger');
    //handler.run();
}