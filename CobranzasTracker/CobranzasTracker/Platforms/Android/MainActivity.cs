using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.OS;
using CobranzasTracker.Platforms.Android;
using CobranzasTracker.Platforms.Android.Services;

namespace CobranzasTracker;

[Activity(Theme = "@style/Maui.SplashTheme", MainLauncher = true, LaunchMode = LaunchMode.SingleTop, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation | ConfigChanges.UiMode | ConfigChanges.ScreenLayout | ConfigChanges.SmallestScreenSize | ConfigChanges.Density)]
public class MainActivity : MauiAppCompatActivity
{
    #region Private Fields
    private const int PermissionRequestCode = 1001;

    #endregion Private Fields

    #region Public Methods

    public override void OnRequestPermissionsResult(int requestCode, string[] permissions, Permission[] grantResults)
    {
        base.OnRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == PermissionRequestCode)
        {
            bool allGranted = true;
            foreach (var result in grantResults)
            {
                if (result != Permission.Granted)
                {
                    allGranted = false;
                    break;
                }
            }

            if (allGranted)
            {
                StartForegroundService();
            }
            else
            {
                // Mostrar mensaje al usuario
                Android.Widget.Toast.MakeText(this, "Se requieren todos los permisos para el funcionamiento de la aplicación", Android.Widget.ToastLength.Long).Show();
            }
        }
    }

    #endregion Public Methods

    #region Protected Methods

    protected override void OnCreate(Bundle savedInstanceState)
    {
        base.OnCreate(savedInstanceState);

        // Solicitar permisos necesarios
        RequestRequiredPermissions();
    }

    protected override void OnResume()
    {
        base.OnResume();

        // Verificar si ya tenemos permisos para iniciar el servicio
        if (PermissionHelper.HasAllRequiredPermissions(this))
        {
            StartForegroundService();
        }
    }

    #endregion Protected Methods

    #region Private Methods

    private void RequestRequiredPermissions()
    {
        if (!PermissionHelper.HasAllRequiredPermissions(this))
        {
            PermissionHelper.RequestPermissions(this);
        }
        else
        {
            StartForegroundService();
        }
    }

    private void StartForegroundService()
    {
        try
        {
            var serviceIntent = new Intent(this, typeof(LocationForegroundService));

            if (Build.VERSION.SdkInt >= BuildVersionCodes.O)
            {
                StartForegroundService(serviceIntent);
            }
            else
            {
                StartService(serviceIntent);
            }
        }
        catch (System.Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Error starting service: {ex.Message}");
        }
    }

    #endregion Private Methods
}