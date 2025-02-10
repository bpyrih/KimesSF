public with sharing class ProjectTaskTriggerService {
    public static void handleAssignedToSharing(List<Project_Task__c> newProjectTasks, Map<Id, Project_Task__c> oldProjectTasksMap) {
        List<Project_Task__c> taskToShare = new List<Project_Task__c>();
        List<Project_Task__c> taskToUnshare = new List<Project_Task__c>();

        for (Project_Task__c projectTask : newProjectTasks) {
            if (checkShare(projectTask, oldProjectTasksMap.get(projectTask.Id))) {
                taskToShare.add(projectTask);
            }

            if (checkUnshare(projectTask, oldProjectTasksMap.get(projectTask.Id))) {
                taskToUnshare.add(oldProjectTasksMap.get(projectTask.Id));
            }
        }

        if (!taskToShare.isEmpty()) {
            shareRecordWithAssignedUser(taskToShare);
        }

        if (!taskToUnshare.isEmpty()) {
            unshareRecordWithAssignedUser(taskToUnshare);
        }
    }

    public static Boolean checkShare(Project_Task__c newProjectTask, Project_Task__c oldProjectTask) {
        return newProjectTask?.Assigned_To__c != oldProjectTask?.Assigned_To__c && newProjectTask?.Assigned_To__c != null;
    }

    public static Boolean checkUnshare(Project_Task__c newProjectTask, Project_Task__c oldProjectTask) {
        return newProjectTask?.Assigned_To__c != oldProjectTask?.Assigned_To__c && oldProjectTask?.Assigned_To__c != null;
    }

    public static void shareRecordWithAssignedUser(List<Project_Task__c> taskToShare) {
        List<Project_Task__Share> taskShares = new List<Project_Task__Share>();
        for (Project_Task__c task : taskToShare) {
            Project_Task__Share taskShare = new Project_Task__Share();
            taskShare.ParentId = task.Id;
            taskShare.UserOrGroupId = task.Assigned_To__c;
            taskShare.AccessLevel = 'Edit';
            taskShare.RowCause = 'Manual';
            taskShares.add(taskShare);
            CustomNotificationSender.sendCustomNotification(task.Id, new Set<String> {task.Assigned_To__c}, 'Task ' + task.Name + ' Assinged To You', 'You are now the assignee of this task. Check the Task tab to see the details and update the task.');
        }

        insert taskShares;
    }

    public static void unshareRecordWithAssignedUser(List<Project_Task__c> taskToUnshare) {
        List<Project_Task__Share> taskSharesToDelete = new List<Project_Task__Share>();
        for (Project_Task__Share taskShare : [
                SELECT Id, ParentId, UserOrGroupId, RowCause
                FROM Project_Task__Share
                WHERE ParentId = :taskToUnshare
        ]) {
            for (Project_Task__c task : taskToUnshare) {
                if (taskShare.UserOrGroupId == task.Assigned_To__c) {
                    taskSharesToDelete.add(taskShare);
                }
            }
        }

        delete taskSharesToDelete; 
    }
}