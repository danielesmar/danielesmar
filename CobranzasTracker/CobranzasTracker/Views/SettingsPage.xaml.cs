namespace CobranzasTracker.Views;

public partial class SettingsPage : ContentPage
{
    #region Public Constructors

    public SettingsPage(SettingsViewModel model)
    {
        InitializeComponent();
        BindingContext = model;
    }

    #endregion Public Constructors
}