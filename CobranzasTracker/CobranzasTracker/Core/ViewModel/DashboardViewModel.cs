using MvvmHelpers;
using System.Windows.Input;

namespace CobranzasTracker.Core.ViewModel;

public class DashboardViewModel : BaseViewModel
{
    #region Private Fields
    private readonly IAuthService _authService;
    private readonly IConfigurationService _configService;
    private readonly ILocationService _locationService;
    private readonly INotificationService _notificationService;

    private int _batteryLevel;
    private Timer _countdownTimer;
    private string _gpsStatus;
    private bool _isMonitoring;
    private DateTime _lastLocationSendTime = DateTime.MinValue;
    private string _lastNotification;
    private string _monitoringStatus;
    private string _nextSendCountdown;
    private string _userName;

    #endregion Private Fields

    #region Public Constructors

    public DashboardViewModel(
        IAuthService authService,
        ILocationService locationService,
        IConfigurationService configService,
        INotificationService notificationService)
    {
        _authService = authService;
        _locationService = locationService;
        _configService = configService;
        _notificationService = notificationService;

        InitializeCommands();
        LoadData();
        StartCountdownTimer();
    }

    #endregion Public Constructors

    #region Public Properties

    public int BatteryLevel
    {
        get => _batteryLevel;
        set => SetProperty(ref _batteryLevel, value);
    }

    public string GpsStatus
    {
        get => _gpsStatus;
        set => SetProperty(ref _gpsStatus, value);
    }

    public bool IsMonitoring
    {
        get => _isMonitoring;
        set => SetProperty(ref _isMonitoring, value);
    }

    public string LastNotification
    {
        get => _lastNotification;
        set => SetProperty(ref _lastNotification, value);
    }

    public ICommand LogoutCommand { get; private set; }

    public string MonitoringStatus
    {
        get => _monitoringStatus;
        set => SetProperty(ref _monitoringStatus, value);
    }

    public string NextSendCountdown
    {
        get => _nextSendCountdown;
        set => SetProperty(ref _nextSendCountdown, value);
    }

    public ICommand OpenSettingsCommand { get; private set; }

    public ICommand RefreshCommand { get; private set; }

    public ICommand SendManualLocationCommand { get; private set; }

    public ICommand ToggleMonitoringCommand { get; private set; }

    public string UserName
    {
        get => _userName;
        set => SetProperty(ref _userName, value);
    }

    #endregion Public Properties

    #region Private Methods

    public void CheckAuthentication()
    {
        // Verificar si el usuario sigue logueado
        if (!_authService.IsUserLoggedIn())
        {
            // Si no está logueado, redirigir al login
            MainThread.BeginInvokeOnMainThread(async () =>
            {
                await Shell.Current.GoToAsync("//LoginPage");
            });
        }
    }

    private async Task<int> GetBatteryLevelAsync()
    {
        // Mock battery level check
        await Task.Delay(100);
        return new Random().Next(20, 100); // Random battery level between 20-100%
    }

    private void InitializeCommands()
    {
        RefreshCommand = new Command(async () => await RefreshDataAsync());
        SendManualLocationCommand = new Command(async () => await SendManualLocationAsync());
        ToggleMonitoringCommand = new Command(async () => await ToggleMonitoringAsync());
        OpenSettingsCommand = new Command(async () => await OpenSettingsAsync());
        LogoutCommand = new Command(async () => await LogoutAsync());
    }

    private async Task<bool> IsGpsEnabledAsync()
    {
        // Mock GPS status check
        await Task.Delay(100);
        return true; // Simulate GPS enabled
    }

    private async void LoadData()
    {
        UserName = _authService.GetCurrentUser();
        await UpdateStatusAsync();
    }

    private async Task LogoutAsync()
    {
        var result = await Application.Current.MainPage.DisplayAlert(
            "Logout",
            "Are you sure you want to logout?",
            "Yes", "No");

        if (result)
        {
            await _authService.LogoutAsync();
            await Shell.Current.GoToAsync("//LoginPage");

            // Actualizar el Shell para ocultar el menú
            if (App.Current.MainPage is AppShell shell)
            {
                shell.UpdateFlyoutBehavior(false);
            }
        }
    }

    private async Task OpenSettingsAsync()
    {
        await Shell.Current.GoToAsync("SettingsPage");
    }

    private async Task RefreshDataAsync()
    {
        IsBusy = true;
        await UpdateStatusAsync();
        IsBusy = false;
    }

    private async Task SendLocationAsync()
    {
        try
        {
            var location = await _locationService.GetCurrentLocationAsync();
            if (location != null)
            {
                var success = await _locationService.SendLocationToApiAsync(location);
                if (success)
                {
                    _lastLocationSendTime = DateTime.UtcNow;
                    LastNotification = $"Location sent at {DateTime.Now:HH:mm:ss}";
                    await UpdateCountdownAsync();
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending location: {ex.Message}");
        }
    }

    private async Task SendManualLocationAsync()
    {
        IsBusy = true;
        await SendLocationAsync();
        IsBusy = false;
    }

    private void StartCountdownTimer()
    {
        _countdownTimer = new Timer(async _ =>
        {
            await UpdateCountdownAsync();
        }, null, TimeSpan.Zero, TimeSpan.FromSeconds(1));
    }

    private async Task ToggleMonitoringAsync()
    {
        if (IsMonitoring)
        {
            await _locationService.StopListeningAsync();
            IsMonitoring = false;
            MonitoringStatus = "Monitoring Stopped";
            await _notificationService.ShowNotification("Monitoring Stopped", "Location tracking has been stopped");
        }
        else
        {
            await _locationService.StartListeningAsync();
            IsMonitoring = true;
            MonitoringStatus = "Monitoring Active";
            await _notificationService.ShowNotification("Monitoring Started", "Location tracking has been started");

            // Send initial location
            await SendLocationAsync();
        }
    }

    private async Task UpdateCountdownAsync()
    {
        try
        {
            var config = await _configService.GetConfigurationAsync();
            var nextSendTime = _lastLocationSendTime.AddMinutes(config.UpdateIntervalMinutes);
            var remainingTime = nextSendTime - DateTime.UtcNow;

            if (remainingTime.TotalMinutes < 0)
            {
                NextSendCountdown = "Due now";
            }
            else
            {
                NextSendCountdown = $"{remainingTime.Minutes}m {remainingTime.Seconds}s until next send";
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating countdown: {ex.Message}");
            NextSendCountdown = "Calculating...";
        }
    }

    private async Task UpdateStatusAsync()
    {
        // Update GPS status
        GpsStatus = await IsGpsEnabledAsync() ? "Enabled" : "Disabled";

        // Update battery level
        BatteryLevel = await GetBatteryLevelAsync();

        // Update monitoring status
        IsMonitoring = _locationService.IsListening();
        MonitoringStatus = IsMonitoring ? "Monitoring Active" : "Monitoring Stopped";

        // Update countdown
        await UpdateCountdownAsync();
    }

    #endregion Private Methods
}