namespace CobranzasTracker.Core.Interfaces;

public interface ISecureStorageService
{
    #region Public Methods

    bool ContainsKey(string key);

    Task<T> GetAsync<T>(string key);

    Task RemoveAsync(string key);

    Task SaveAsync<T>(string key, T value);

    #endregion Public Methods
}