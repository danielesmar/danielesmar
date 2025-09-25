using System.Text.Json;

namespace CobranzasTracker.Infrastructure.Services;

public class SecureStorageService : ISecureStorageService
{
    #region Public Methods

    public bool ContainsKey(string key)
    {
        return SecureStorage.Default.GetAsync(key).Result != null;
    }

    public async Task<T> GetAsync<T>(string key)
    {
        try
        {
            var json = await SecureStorage.Default.GetAsync(key);
            if (string.IsNullOrEmpty(json))
                return default;

            return JsonSerializer.Deserialize<T>(json);
        }
        catch (Exception ex)
        {
            throw;
        }
    }

    public Task RemoveAsync(string key)
    {
        SecureStorage.Default.Remove(key);
        return Task.CompletedTask;
    }

    public async Task SaveAsync<T>(string key, T value)
    {
        var json = JsonSerializer.Serialize(value);
        await SecureStorage.Default.SetAsync(key, json);
    }

    #endregion Public Methods
}