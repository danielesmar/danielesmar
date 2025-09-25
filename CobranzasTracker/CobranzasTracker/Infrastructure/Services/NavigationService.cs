namespace CobranzasTracker.Infrastructure.Services;

public class NavigationService : INavigationService
{
    #region Public Methods

    public async Task GoBackAsync()
    {
        await Shell.Current.GoToAsync("..");
    }

    public async Task NavigateToDashboardAsync()
    {
        await Shell.Current.GoToAsync("//DashboardPage");
    }

    public async Task NavigateToLoginAsync()
    {
        await Shell.Current.GoToAsync("//LoginPage");
    }

    #endregion Public Methods
}