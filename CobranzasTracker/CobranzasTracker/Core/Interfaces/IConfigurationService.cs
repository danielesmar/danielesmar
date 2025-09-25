using CobranzasTracker.Core.Models;

namespace CobranzasTracker.Core.Interfaces;

public interface IConfigurationService
{
    #region Public Methods

    Task<ApiConfiguration> GetConfigurationAsync();

    Task<int> GetRemainingMinutesUntilNextSend();

    Task<bool> ShouldSendDataAsync();

    #endregion Public Methods
}