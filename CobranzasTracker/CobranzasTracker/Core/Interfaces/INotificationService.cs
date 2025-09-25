namespace CobranzasTracker.Core.Interfaces;

public interface INotificationService
{
    #region Public Methods

    Task SendDeviceStatusNotification(bool isPoweredOn);

    Task SendGpsStatusNotification(bool isEnabled);

    Task ShowNotification(string title, string message);

    #endregion Public Methods
}