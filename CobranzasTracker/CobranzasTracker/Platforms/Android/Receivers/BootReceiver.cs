using Android.App;
using Android.Content;
using Android.OS;
using AndroidX.Core.Content;
using static Android.Manifest;
using AndroidPermission = Android.Content.PM;

namespace CobranzasTracker.Platforms.Android.Receivers;

[BroadcastReceiver(Enabled = true, Exported = true, Name = "com.banpro.cobranzastracker.receivers.BootReceiver")]
[IntentFilter(new[] { Intent.ActionBootCompleted })]
public class BootReceiver : BroadcastReceiver
{
    #region Public Methods

    public override void OnReceive(Context context, Intent intent)
    {
        if (intent.Action == Intent.ActionBootCompleted)
        {
            // Verificar permisos antes de iniciar el servicio
            if (HasRequiredPermissions(context))
            {
                var serviceIntent = new Intent(context,
                    Java.Lang.Class.ForName("com.banpro.cobranzastracker.services.LocationForegroundService"));

                if (Build.VERSION.SdkInt >= BuildVersionCodes.O)
                {
                    context.StartForegroundService(serviceIntent);
                }
                else
                {
                    context.StartService(serviceIntent);
                }
            }
        }
    }

    #endregion Public Methods

    #region Private Methods

    private bool HasRequiredPermissions(Context context)
    {
        return ContextCompat.CheckSelfPermission(context, Permission.AccessFineLocation) == AndroidPermission.Permission.Granted &&
               ContextCompat.CheckSelfPermission(context, Permission.AccessCoarseLocation) == AndroidPermission.Permission.Granted &&
               ContextCompat.CheckSelfPermission(context, Permission.ForegroundServiceLocation) == AndroidPermission.Permission.Granted;
    }

    #endregion Private Methods
}