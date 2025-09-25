using MvvmHelpers;
using System.Windows.Input;

namespace CobranzasTracker.Core.ViewModel;

public class SettingsViewModel : BaseViewModel
{
    #region Private Fields
    private readonly IConfigurationService _configService;
    private readonly INotificationService _notificationService;

    private bool _backgroundPermissionGranted;
    private bool _batteryOptimizationDisabled;
    private bool _gpsPermissionGranted;
    private bool _startOnBootEnabled;
    private string _timeRange;
    private int _updateInterval;

    #endregion Private Fields

    #region Public Constructors

    public SettingsViewModel(
        IConfigurationService configService,
        INotificationService notificationService)
    {
        _configService = configService;
        _notificationService = notificationService;

        InitializeCommands();
        LoadSettings();
    }

    #endregion Public Constructors

    #region Public Properties

    public bool BackgroundPermissionGranted
    {
        get => _backgroundPermissionGranted;
        set => SetProperty(ref _backgroundPermissionGranted, value);
    }

    public bool BatteryOptimizationDisabled
    {
        get => _batteryOptimizationDisabled;
        set => SetProperty(ref _batteryOptimizationDisabled, value);
    }

    public bool GpsPermissionGranted
    {
        get => _gpsPermissionGranted;
        set => SetProperty(ref _gpsPermissionGranted, value);
    }

    public ICommand OpenAppSettingsCommand { get; private set; }

    public ICommand RequestPermissionsCommand { get; private set; }

    public ICommand SaveSettingsCommand { get; private set; }

    public bool StartOnBootEnabled
    {
        get => _startOnBootEnabled;
        set => SetProperty(ref _startOnBootEnabled, value);
    }

    public ICommand TestNotificationCommand { get; private set; }

    public string TimeRange
    {
        get => _timeRange;
        set => SetProperty(ref _timeRange, value);
    }

    public int UpdateInterval
    {
        get => _updateInterval;
        set => SetProperty(ref _updateInterval, value);
    }

    #endregion Public Properties

    #region Private Methods

    private Task<bool> CheckBackgroundPermissionAsync() => Task.FromResult(true);

    private Task<bool> CheckBatteryOptimizationAsync() => Task.FromResult(false);

    // Mock permission check methods
    private Task<bool> CheckGpsPermissionAsync() => Task.FromResult(true);

    private Task<bool> CheckStartOnBootAsync() => Task.FromResult(true);

    private void InitializeCommands()
    {
        SaveSettingsCommand = new Command(async () => await SaveSettingsAsync());
        RequestPermissionsCommand = new Command(async () => await RequestPermissionsAsync());
        OpenAppSettingsCommand = new Command(async () => await OpenAppSettingsAsync());
        TestNotificationCommand = new Command(async () => await TestNotificationAsync());
    }

    private async void LoadSettings()
    {
        var config = await _configService.GetConfigurationAsync();
        UpdateInterval = config.UpdateIntervalMinutes;
        TimeRange = $"{config.StartTime:hh\\:mm} - {config.EndTime:hh\\:mm}";

        // Load permission status (mock values)
        GpsPermissionGranted = await CheckGpsPermissionAsync();
        BatteryOptimizationDisabled = await CheckBatteryOptimizationAsync();
        BackgroundPermissionGranted = await CheckBackgroundPermissionAsync();
        StartOnBootEnabled = await CheckStartOnBootAsync();
    }

    private async Task OpenAppSettingsAsync()
    {
        // Open device app settings
        if (DeviceInfo.Platform == DevicePlatform.Android)
        {
            // Android implementation to open app settings
        }
        else if (DeviceInfo.Platform == DevicePlatform.iOS)
        {
            // iOS implementation to open app settings
        }

        await Task.CompletedTask;
    }

    private Task RequestBackgroundPermissionAsync() => Task.Delay(300);

    private Task RequestBatteryOptimizationAsync() => Task.Delay(300);

    // Mock permission request methods
    private Task RequestGpsPermissionAsync() => Task.Delay(300);

    private async Task RequestPermissionsAsync()
    {
        IsBusy = true;

        // Request all necessary permissions
        await RequestGpsPermissionAsync();
        await RequestBatteryOptimizationAsync();
        await RequestBackgroundPermissionAsync();

        // Reload permission status
        GpsPermissionGranted = await CheckGpsPermissionAsync();
        BatteryOptimizationDisabled = await CheckBatteryOptimizationAsync();
        BackgroundPermissionGranted = await CheckBackgroundPermissionAsync();

        IsBusy = false;
    }

    private async Task SaveSettingsAsync()
    {
        IsBusy = true;

        // In a real app, this would save to the backend API
        await Task.Delay(500); // Simulate API call

        await _notificationService.ShowNotification("Settings Saved", "Your settings have been updated successfully");
        IsBusy = false;
    }

    private async Task TestNotificationAsync()
    {
        await _notificationService.ShowNotification("Test Notification", "This is a test notification from Location Tracker");
    }

    #endregion Private Methods
}