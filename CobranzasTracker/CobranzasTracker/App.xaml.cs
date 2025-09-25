using CobranzasTracker.Views;
using Microsoft.Extensions.DependencyInjection;
using System;

namespace CobranzasTracker;

public partial class App : Application
{
    #region Public Constructors

    public App()
    {
        InitializeComponent();
    }

    #endregion Public Constructors

    #region Protected Methods

    protected override Window CreateWindow(IActivationState? activationState)
    {
        return new Window(new AppShell());
    }

    #endregion Protected Methods
}