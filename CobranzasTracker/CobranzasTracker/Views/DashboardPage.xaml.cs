namespace CobranzasTracker.Views;

public partial class DashboardPage : ContentPage
{
    #region Public Constructors

    public DashboardPage(DashboardViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }

    #endregion Public Constructors

    #region Protected Methods

    protected override void OnAppearing()
    {
        base.OnAppearing();

        // Verificar que aún está logueado al aparecer la página
        if (BindingContext is DashboardViewModel viewModel)
        {
            viewModel.CheckAuthentication();
        }
    }

    #endregion Protected Methods
}