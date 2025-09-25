namespace CobranzasTracker.Views;

public partial class LoginPage : ContentPage
{
    #region Private Fields
    private readonly IAuthService _authService;

    #endregion Private Fields

    #region Public Constructors

    public LoginPage(LoginViewModel viewModel, IAuthService authService)
    {
        InitializeComponent();
        BindingContext = viewModel;
        _authService = authService;

        CheckIfAlreadyLoggedIn();
    }

    #endregion Public Constructors

    #region Protected Methods

    protected override void OnAppearing()
    {
        base.OnAppearing();
        CheckIfAlreadyLoggedIn();
    }

    #endregion Protected Methods

    #region Private Methods

    private async void CheckIfAlreadyLoggedIn()
    {
        // Si ya está logueado, redirigir al Dashboard
        if (_authService?.IsUserLoggedIn() == true)
        {
            await Shell.Current.GoToAsync("//DashboardPage");
        }
    }

    #endregion Private Methods
}