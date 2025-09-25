using CobranzasTracker.Core.Models;

namespace CobranzasTracker.Core.Interfaces;

public interface ILocationService
{
    #region Public Methods

    Task<LocationData> GetCurrentLocationAsync();

    bool IsListening();

    Task<bool> SendLocationToApiAsync(LocationData location);

    Task StartListeningAsync();

    Task StopListeningAsync();

    #endregion Public Methods
}