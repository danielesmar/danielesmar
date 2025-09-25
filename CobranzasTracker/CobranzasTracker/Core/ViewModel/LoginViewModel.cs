using MvvmHelpers;
using System.Windows.Input;

namespace CobranzasTracker.Core.ViewModel;

public class LoginViewModel : BaseViewModel
{
    #region Private Fields
    private readonly IAuthService _authService;
    private readonly INavigationService _navigationService;
    private string _errorMessage;
    private bool _isBusy;
    private Command _loginCommand;
    private string _password;
    private string _username;

    #endregion Private Fields

    #region Public Constructors

    public LoginViewModel(IAuthService authService, INavigationService navigationService)
    {
        _authService = authService;
        _navigationService = navigationService;
        _loginCommand = new Command(async () => await LoginAsync(), () => !IsBusy);
    }

    #endregion Public Constructors

    #region Public Properties

    public string ErrorMessage
    {
        get => _errorMessage;
        set => SetProperty(ref _errorMessage, value);
    }

    public bool IsBusy
    {
        get => _isBusy;
        set
        {
            SetProperty(ref _isBusy, value);
            _loginCommand.ChangeCanExecute();
        }
    }

    // Mantener como ICommand pero usar campo interno Command
    public ICommand LoginCommand => _loginCommand;

    public string Password
    {
        get => _password;
        set => SetProperty(ref _password, value);
    }

    public string Username
    {
        get => _username;
        set => SetProperty(ref _username, value);
    }

    #endregion Public Properties

    #region Private Methods

    private async Task LoginAsync()
    {
        if (IsBusy) return;

        ErrorMessage = string.Empty;

        if (string.IsNullOrWhiteSpace(Username))
        {
            ErrorMessage = "Username is required";
            return;
        }

        if (string.IsNullOrWhiteSpace(Password))
        {
            ErrorMessage = "Password is required";
            return;
        }

        IsBusy = true;

        try
        {
            var success = await _authService.LoginAsync(Username, Password);
            Console.WriteLine($"Login result: {success}");

            if (success)
            {
                await Application.Current.MainPage.DisplayAlert("Success", "Login successful", "OK");

                // Esperar un momento antes de navegar
                await Task.Delay(100);

                // Verificar que Shell.Current no sea null
                if (Shell.Current != null)
                {
                    Console.WriteLine("Navigating to Dashboard...");
                    await Shell.Current.GoToAsync("//DashboardPage", true);
                    Console.WriteLine("Navigation completed");
                }
                else
                {
                    Console.WriteLine("Shell.Current is null!");
                    // Fallback: usar Application.Current.MainPage
                    if (Application.Current?.MainPage is Shell shell)
                    {
                        Console.WriteLine("Navigating to Dashboard...");
                        await shell.GoToAsync("//DashboardPage", true);
                        Console.WriteLine("Navigation completed");
                    }
                }
            }
            else
            {
                ErrorMessage = "Invalid username or password";
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Login error: {ex.Message}");
            ErrorMessage = $"Login failed: {ex.Message}";
        }
        finally
        {
            IsBusy = false;
        }
    }

    #endregion Private Methods
}