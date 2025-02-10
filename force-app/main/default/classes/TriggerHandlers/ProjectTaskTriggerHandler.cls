public with sharing class ProjectTaskTriggerHandler {
    public static void afterInsert(List<Project_Task__c> newProjectTasks, Map<Id, Project_Task__c> newProjectTasksMap) {
        ProjectTaskTriggerService.handleAssignedToSharing(newProjectTasks, new Map<Id, Project_Task__c>());
    }

    public static void afterUpdate(List<Project_Task__c> newProjectTasks, Map<Id, Project_Task__c> newProjectTasksMap, List<Project_Task__c> oldProjectTasks, Map<Id, Project_Task__c> oldProjectTasksMap) {
        ProjectTaskTriggerService.handleAssignedToSharing(newProjectTasks, oldProjectTasksMap);
    }
}