using Syncfusion.Maui.Toolkit.SegmentedControl;

namespace CobranzasTracker;

public partial class AppShell : Shell
{
    #region Private Fields
    private IAuthService _authService;

    #endregion Private Fields

    #region Public Constructors

    public AppShell()
    {
        InitializeComponent();
        this.HandlerChanged += OnHandlerChanged;
    }

    private async void InitializeAuthentication()
    {
        // Verificar y renovar token si es necesario
        var isValid = await _authService.CheckAndRenewTokenAsync();
        Console.WriteLine($"Token validation: {isValid}");

        CheckAuthentication();
    }

    private void OnAuthenticationStateChanged(object sender, EventArgs e)
    {
        CheckAuthentication();
    }

    private void OnHandlerChanged(object sender, EventArgs e)
    {
        if (Handler != null)
        {
            _authService = Handler.MauiContext.Services.GetService<IAuthService>();
            InitializeAuthentication();
            this.HandlerChanged -= OnHandlerChanged; // Remover el evento después de usarlo
        }
    }

    #endregion Public Constructors

    #region Public Methods

    public void UpdateFlyoutBehavior(bool isLoggedIn)
    {
        FlyoutBehavior = isLoggedIn ? FlyoutBehavior.Flyout : FlyoutBehavior.Disabled;
    }

    #endregion Public Methods

    #region Protected Methods

    protected override void OnAppearing()
    {
        base.OnAppearing();
        CheckAuthentication();
    }

    #endregion Protected Methods

    #region Private Methods

    protected override void OnDisappearing()
    {
        // Limpiar suscripción
        if (_authService is AuthService authServiceImpl)
        {
            authServiceImpl.AuthenticationStateChanged -= OnAuthenticationStateChanged;
        }
        base.OnDisappearing();
    }

    private async void CheckAuthentication()
    {
        try
        {
            var isLoggedIn = _authService?.IsUserLoggedIn() == true;
            FlyoutBehavior = isLoggedIn ? FlyoutBehavior.Flyout : FlyoutBehavior.Disabled;
            Console.WriteLine($"CheckAuthentication: isLoggedIn = {isLoggedIn}");

            await MainThread.InvokeOnMainThreadAsync(async () =>
            {
                if (isLoggedIn)
                {
                    // Verificar si ya estamos en el Dashboard para evitar navegación duplicada
                    if (CurrentState?.Location?.ToString()?.Contains("DashboardPage") != true)
                    {
                        await GoToAsync("//DashboardPage", true);
                    }
                }
                else
                {
                    // Verificar si ya estamos en el Login para evitar navegación duplicada
                    if (CurrentState?.Location?.ToString()?.Contains("LoginPage") != true)
                    {
                        await GoToAsync("//LoginPage", true);
                    }
                }
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Authentication check failed: {ex.Message}");
            // Fallback: ir al login
            FlyoutBehavior = FlyoutBehavior.Disabled;
            await GoToAsync("//LoginPage");
        }
    }

    // Manejador del evento SelectionChanged
    private void SfSegmentedControl_SelectionChanged(object sender, Syncfusion.Maui.Toolkit.SegmentedControl.SelectionChangedEventArgs e)
    {
        if (sender is SfSegmentedControl segmentedControl)
        {
            int selectedIndex = (int)segmentedControl.SelectedIndex;

            // Cambiar el tema según la selección
            if (selectedIndex == 0) // Tema claro
            {
                Application.Current.UserAppTheme = AppTheme.Light;
            }
            else if (selectedIndex == 1) // Tema oscuro
            {
                Application.Current.UserAppTheme = AppTheme.Dark;
            }
        }
    }

    #endregion Private Methods
}