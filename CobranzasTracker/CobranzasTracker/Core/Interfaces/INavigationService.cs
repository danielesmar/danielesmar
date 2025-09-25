namespace CobranzasTracker.Core.Interfaces;

public interface INavigationService
{
    #region Public Methods

    Task GoBackAsync();

    Task NavigateToDashboardAsync();

    Task NavigateToLoginAsync();

    #endregion Public Methods
}