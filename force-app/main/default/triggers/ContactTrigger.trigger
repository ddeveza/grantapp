trigger ContactTrigger on Contact (
    before insert,
    before update
) {
    ContactTriggerHandler.handle(Trigger.new);
}