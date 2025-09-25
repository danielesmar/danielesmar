namespace CobranzasTracker.Infrastructure.Services;

public class LocationService : ILocationService
{
    #region Private Fields
    private readonly IAuthService _authService;
    private readonly IBattery _battery;
    private readonly IConfigurationService _configService;
    private readonly IGeolocation _geolocation;
    private CancellationTokenSource _cts;
    private bool _isListening = false;
    private Timer _locationTimer;

    #endregion Private Fields

    #region Public Constructors

    public LocationService(IGeolocation geolocation, IBattery battery, IAuthService authService, IConfigurationService configService)
    {
        _geolocation = geolocation;
        _battery = battery;
        _authService = authService;
        _configService = configService;
    }

    #endregion Public Constructors

    #region Public Methods

    public void Dispose()
    {
        _locationTimer?.Dispose();
        _cts?.Dispose();
    }

    public async Task<LocationData> GetCurrentLocationAsync()
    {
        try
        {
            var request = new GeolocationRequest(GeolocationAccuracy.Best, TimeSpan.FromSeconds(10));
            var location = await _geolocation.GetLocationAsync(request, _cts?.Token ?? default);

            if (location != null)
            {
                return new LocationData
                {
                    Latitude = location.Latitude,
                    Longitude = location.Longitude,
                    Timestamp = DateTime.UtcNow,
                    Accuracy = location.Accuracy.HasValue && location.Accuracy.Value < 50 ? "Precise" : "Approximate",
                    BatteryLevel = (int)(_battery.ChargeLevel * 100),
                    Username = _authService.GetCurrentUser()
                };
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting location: {ex.Message}");
        }

        return null;
    }

    public bool IsListening() => _isListening;

    public async Task<bool> SendLocationToApiAsync(LocationData location)
    {
        // Check if we should send data based on configuration
        var shouldSend = await _configService.ShouldSendDataAsync();
        if (!shouldSend)
        {
            Console.WriteLine("Not sending location - outside configured time range");
            return false;
        }

        // Mock API call
        await Task.Delay(500);
        Console.WriteLine($"Sending location: {location.Latitude}, {location.Longitude}");
        return true; // Mock success
    }

    public async Task StartListeningAsync()
    {
        if (_isListening) return;

        _isListening = true;
        _cts = new CancellationTokenSource();

        // Start background timer
        _locationTimer = new Timer(async _ =>
        {
            await SendLocationIfNeededAsync();
        }, null, TimeSpan.Zero, TimeSpan.FromMinutes(1));
    }

    public Task StopListeningAsync()
    {
        _isListening = false;
        _cts?.Cancel();
        _locationTimer?.Dispose();
        _locationTimer = null;
        return Task.CompletedTask;
    }

    #endregion Public Methods

    #region Private Methods

    private async Task SendLocationIfNeededAsync()
    {
        if (!_isListening) return;

        try
        {
            var location = await GetCurrentLocationAsync();
            if (location != null)
            {
                await SendLocationToApiAsync(location);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error in background location send: {ex.Message}");
        }
    }

    #endregion Private Methods
}