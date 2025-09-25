namespace CobranzasTracker.Core.Interfaces;

public interface IAuthService
{
    #region Public Methods

    Task<bool> CheckAndRenewTokenAsync();

    string GetCurrentUser();

    bool IsUserLoggedIn();

    Task<bool> LoginAsync(string username, string password);

    Task<bool> LogoutAsync();

    #endregion Public Methods
}