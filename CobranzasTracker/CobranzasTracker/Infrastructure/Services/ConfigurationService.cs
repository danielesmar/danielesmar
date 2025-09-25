namespace CobranzasTracker.Infrastructure.Services;

public class ConfigurationService : IConfigurationService
{
    #region Private Fields
    private const string ConfigKey = "api_configuration";
    private readonly ISecureStorageService _secureStorage;
    private ApiConfiguration _cachedConfig;
    private DateTime _lastConfigUpdate = DateTime.MinValue;

    #endregion Private Fields

    #region Public Constructors

    public ConfigurationService(ISecureStorageService secureStorage)
    {
        _secureStorage = secureStorage;
    }

    #endregion Public Constructors

    #region Public Methods

    public async Task<ApiConfiguration> GetConfigurationAsync()
    {
        // Check if we have a cached config that's less than 1 hour old
        if (_cachedConfig != null && (DateTime.UtcNow - _lastConfigUpdate).TotalHours < 1)
        {
            return _cachedConfig;
        }

        // Mock API call to get configuration
        await Task.Delay(300); // Simulate network delay

        // Mock configuration data
        var config = new ApiConfiguration
        {
            UpdateIntervalMinutes = 15,
            StartTime = new TimeSpan(8, 0, 0),
            EndTime = new TimeSpan(17, 0, 0),
            LastUpdated = DateTime.UtcNow
        };

        // Save to cache and secure storage
        _cachedConfig = config;
        _lastConfigUpdate = DateTime.UtcNow;
        await _secureStorage.SaveAsync(ConfigKey, config);

        return config;
    }

    public async Task<int> GetRemainingMinutesUntilNextSend()
    {
        var config = await GetConfigurationAsync();
        var lastSendTime = await GetLastSendTimeAsync();
        var nextSendTime = lastSendTime.AddMinutes(config.UpdateIntervalMinutes);

        return (int)(nextSendTime - DateTime.UtcNow).TotalMinutes;
    }

    public async Task<bool> ShouldSendDataAsync()
    {
        var config = await GetConfigurationAsync();
        var currentTime = DateTime.Now.TimeOfDay;

        // Check if current time is within the allowed range
        var shouldSendByTime = currentTime >= config.StartTime && currentTime <= config.EndTime;

        // Additional logic can be added here (battery level, network availability, etc.)
        return shouldSendByTime;
    }

    #endregion Public Methods

    #region Private Methods

    private async Task<DateTime> GetLastSendTimeAsync()
    {
        var lastSend = await _secureStorage.GetAsync<DateTime>("last_send_time");
        return lastSend == default ? DateTime.UtcNow : lastSend;
    }

    #endregion Private Methods
}