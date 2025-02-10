public class CustomNotificationSender {
    public static Boolean sendCustomNotification(String targetId, Set<String> recipientUserIds, String notificationTitle, String notificationBody) {
        Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
        CustomNotificationType notificationType = 
        [
            SELECT Id, DeveloperName 
            FROM CustomNotificationType 
            WHERE DeveloperName='Kimes_Internal'
        ];
        
        customNotification.setNotificationTypeId(notificationType.Id);
        customNotification.setTitle(notificationTitle);
        customNotification.setBody(notificationBody);
        
        customNotification.setTargetId(targetId);
        
        try {
            customNotification.send(recipientUserIds);
            System.debug('Notification sent successfully');
            return true;
        } catch (Exception e) {
            System.debug('Error sending notification: ' + e.getMessage());
            return false;
        }
    }
}