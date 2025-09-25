using Microsoft.Maui.ApplicationModel;

namespace CobranzasTracker.Services;

public class PermissionService
{
    #region Public Methods

    public async Task<bool> CheckLocationPermissions()
    {
        try
        {
            var status = await Permissions.CheckStatusAsync<Permissions.LocationWhenInUse>();
            return status == PermissionStatus.Granted;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> RequestLocationPermissions()
    {
        try
        {
            // Solicitar permisos básicos de ubicación
            var status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();

            if (status != PermissionStatus.Granted)
                return false;

            // Para Android, solicitar permisos de background
#if ANDROID
            status = await Permissions.RequestAsync<Permissions.LocationAlways>();
#endif

            return status == PermissionStatus.Granted;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error solicitando permisos: {ex.Message}");
            return false;
        }
    }

    #endregion Public Methods
}