public with sharing class ProjectTaskTriggerService {
    public static void handleAssignedToSharing(List<Project_Task__c> newProjectTasks, Map<Id, Project_Task__c> oldProjectTasksMap) {
        List<Project_Task__c> taskToShare = new List<Project_Task__c>();
        List<Project_Task__c> taskToUnshare = new List<Project_Task__c>();

        for (Project_Task__c projectTask : newProjectTasks) {
            if (checkShare(projectTask, oldProjectTasksMap.get(projectTask.Id))) {
                taskToShare.add(projectTask);
            }

            if (checkUnshare(projectTask, oldProjectTasksMap.get(projectTask.Id))) {
                taskToUnshare.add(projectTask);
            }
        }
    }

    public static Boolean checkShare(Project_Task__c newProjectTask, Project_Task__c oldProjectTask) {
        return newProjectTask?.Assigned_To__c != oldProjectTask?.Assigned_To__c && newProjectTask?.Assigned_To__c != null;
        // if (oldProjectTask == null) {
        //     return newProjectTask.Assigned_To__c != null;
        // } else {
        //     return (newProjectTask.Assigned_To__c != oldProjectTask.Assigned_To__c) && newProjectTask.Assigned_To__c != null;
        // }
    }

    public static Boolean checkUnshare(Project_Task__c newProjectTask, Project_Task__c oldProjectTask) {
        return newProjectTask?.Assigned_To__c != oldProjectTask?.Assigned_To__c && oldProjectTask?.Assigned_To__c != null;
        // if (oldProjectTask?.Assigned_To__c == null) {
        //     return false;
        // } else {
        //     return newProjectTask.Assigned_To__c != oldProjectTask.Assigned_To__c;
        // }
    }
}