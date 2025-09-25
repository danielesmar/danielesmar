using Android;
using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.Graphics.Drawables;
using Android.OS;
using AndroidX.Core.App;
using AndroidX.Core.Content;
using AndroidApp = Android.App.Application;

namespace CobranzasTracker.Platforms.Android.Services;

[Service(Enabled = true, Exported = true,
         Name = "com.banpro.cobranzastracker.services.LocationForegroundService",
         ForegroundServiceType = ForegroundService.TypeLocation)]
public class LocationForegroundService : Service
{
    #region Private Fields
    private const string NotificationChannelId = "location_foreground_channel";
    private const int ServiceNotificationId = 10001;

    #endregion Private Fields

    #region Public Methods

    public override IBinder OnBind(Intent intent) => null;

    public override StartCommandResult OnStartCommand(Intent intent, StartCommandFlags flags, int startId)
    {
        if (!HasRequiredPermissions())
        {
            StopSelf();
            return StartCommandResult.NotSticky;
        }

        CreateNotificationChannel();
        var notification = CreateNotification();

        StartForeground(ServiceNotificationId, notification);

        return StartCommandResult.Sticky;
    }

    #endregion Public Methods

    #region Private Methods

    private Notification CreateNotification()
    {
        var intent = new Intent(AndroidApp.Context, typeof(MainActivity));
        intent.AddFlags(ActivityFlags.SingleTop);

        var pendingIntentFlags = PendingIntentFlags.Immutable;
        if (Build.VERSION.SdkInt < BuildVersionCodes.S)
        {
            pendingIntentFlags = PendingIntentFlags.UpdateCurrent;
        }

        var pendingIntent = PendingIntent.GetActivity(AndroidApp.Context, 0, intent, pendingIntentFlags);

        // Usar NotificationCompat.Builder para mejor compatibilidad
        var builder = new NotificationCompat.Builder(this, NotificationChannelId)
            .SetContentTitle("Cobranzas Tracker")
            .SetContentText("Monitoreo de ubicación activo")
            .SetContentIntent(pendingIntent)
            .SetOngoing(true)
            .SetOnlyAlertOnce(true);

        // Intentar establecer el icono, pero manejar posible null
        try
        {
            builder.SetSmallIcon(Resource.Drawable.notification_template_icon_bg);
        }
        catch
        {
            // Usar icono por defecto si el específico no está disponible
            builder.SetSmallIcon(Resource.Drawable.notification_template_icon_bg);
        }

        return builder.Build();
    }

    private void CreateNotificationChannel()
    {
        // NotificationChannel solo disponible en Android 8.0+ (API 26)
        if (Build.VERSION.SdkInt >= BuildVersionCodes.O)
        {
#pragma warning disable CA1416 // Validamos la versión con Build.VERSION.SdkInt
            var channel = new NotificationChannel(
                NotificationChannelId,
                "Servicio de Ubicación",
                NotificationImportance.Low
            )
            {
                Description = "Servicio para rastreo de ubicación en segundo plano"
            };

            var notificationManager = GetSystemService(NotificationService) as NotificationManager;
            notificationManager?.CreateNotificationChannel(channel);
#pragma warning restore CA1416
        }
    }

    private bool HasRequiredPermissions()
    {
        var hasFineLocation = ContextCompat.CheckSelfPermission(this, Manifest.Permission.AccessFineLocation) == (int)Permission.Granted;
        var hasCoarseLocation = ContextCompat.CheckSelfPermission(this, Manifest.Permission.AccessCoarseLocation) == (int)Permission.Granted;
        var hasForegroundService = ContextCompat.CheckSelfPermission(this, Manifest.Permission.ForegroundService) == (int)Permission.Granted;

        var hasForegroundServiceLocation = true;
        var hasBackgroundLocation = true;

        // Solo verificar estos permisos en versiones que los soporten
        if (Build.VERSION.SdkInt >= BuildVersionCodes.Q) // Android 10+
        {
            hasBackgroundLocation = ContextCompat.CheckSelfPermission(this, Manifest.Permission.AccessBackgroundLocation) == (int)Permission.Granted;
        }

        if (Build.VERSION.SdkInt >= BuildVersionCodes.S) // Android 12+
        {
            hasForegroundServiceLocation = ContextCompat.CheckSelfPermission(this, Manifest.Permission.ForegroundServiceLocation) == (int)Permission.Granted;
        }

        return hasFineLocation && hasCoarseLocation && hasForegroundService &&
               hasForegroundServiceLocation && hasBackgroundLocation;
    }

    #endregion Private Methods
}